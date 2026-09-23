/*
 * Snowboard physics: segmented elastic board on trimesh terrain
 * Board = 8 rigid box segments connected by spring-hinge joints (wood flex)
 * Terrain = trimesh from heightfield (soft contact = snow compression)
 * Rider = 2 bodies (legs + torso) attached to center segment
 * ALL dynamics from ODE collision + gravity. No hack forces.
 *
 * Build: cc -shared -fPIC -O2 -o libsnowboard_helper.so snowboard_helper.c $(pkg-config --cflags --libs ode) -lm
 */
#include <ode/ode.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_SPRAY 512
#define NUM_SEG   8
#define NUM_JOINT 7

static dWorldID world;
static dSpaceID space;
static dJointGroupID contacts;

/* Terrain trimesh */
static dGeomID terrain_geom;
static dTriMeshDataID terrain_mesh_data;
static float *tri_verts = NULL;
static dTriIndex *tri_indices = NULL;

/* Heightfield for terrain_height() sampling */
static float *hf_data = NULL;
static int hf_w = 0, hf_h = 0;
static float hf_sx = 0, hf_sz = 0;

/* Board segments */
static struct {
    dBodyID body;
    dGeomID geom;
    float half_len;
} seg[NUM_SEG];
static dJointID seg_joint[NUM_JOINT];

/* Board dimensions */
static float board_length, board_width, board_thick;

/* Rider */
static dBodyID lower_body = NULL, upper_body = NULL;
static dGeomID lower_geom, upper_geom;
static dJointID ankle_front, ankle_rear, hip_joint, hip_motor;
/* Rider visual bodies: lightweight. Main 69kg lives on seg[2]/seg[5] bindings. */
static float lower_mass_kg = 3.0, upper_mass_kg = 3.0;
static float lower_h = 0.8, upper_h = 0.7;
static int has_rider = 1;

/* State */
static float current_speed = 0;
static float edge_angle = 0;
static float rider_fore_aft = 0, rider_lean = 0;

/* Terrain height at world position (bilinear interpolation) */
static float terrain_height(float wx, float wz) {
    if (!hf_data || hf_sx <= 0 || hf_sz <= 0) return 0;
    float fx = wx / hf_sx * (hf_w - 1);
    float fz = wz / hf_sz * (hf_h - 1);
    int ix = (int)fx, iz = (int)fz;
    if (ix < 0) ix = 0; if (ix >= hf_w - 1) ix = hf_w - 2;
    if (iz < 0) iz = 0; if (iz >= hf_h - 1) iz = hf_h - 2;
    float u = fx - ix, v = fz - iz;
    float h00 = hf_data[iz * hf_w + ix];
    float h10 = hf_data[iz * hf_w + ix + 1];
    float h01 = hf_data[(iz + 1) * hf_w + ix];
    float h11 = hf_data[(iz + 1) * hf_w + ix + 1];
    return h00*(1-u)*(1-v) + h10*u*(1-v) + h01*(1-u)*v + h11*u*v;
}

/* Spray particles */
static struct { float x,y,z, vx,vy,vz, age,life,size; } spray[MAX_SPRAY];
static int spray_head = 0, spray_count = 0;

static void emit_spray(float x, float y, float z, float vx, float vy, float vz, float speed) {
    int n = (int)(speed * 12);
    if (n > 6) n = 6;
    for (int i = 0; i < n; i++) {
        int idx = spray_head;
        spray_head = (spray_head + 1) % MAX_SPRAY;
        if (spray_count < MAX_SPRAY) spray_count++;
        float spread = 0.3 + speed * 0.15;
        spray[idx].x = x + ((float)rand()/RAND_MAX - 0.5) * 0.1;
        spray[idx].y = y + ((float)rand()/RAND_MAX) * 0.02;
        spray[idx].z = z + ((float)rand()/RAND_MAX - 0.5) * 0.1;
        spray[idx].vx = vx * 0.3 + ((float)rand()/RAND_MAX - 0.5) * spread;
        spray[idx].vy = 0.5 + (float)rand()/RAND_MAX * speed * 0.4;
        spray[idx].vz = vz * 0.3 + ((float)rand()/RAND_MAX - 0.5) * spread;
        spray[idx].age = 0;
        spray[idx].life = 0.8 + (float)rand()/RAND_MAX * 0.5;
        spray[idx].size = 0.01 + (float)rand()/RAND_MAX * 0.02;
    }
}

/* Collision callback */
static void near_cb(void *data, dGeomID o1, dGeomID o2) {
    /* Skip rider geoms (rider geoms have bit 0x02 only) */
    unsigned cb1 = dGeomGetCategoryBits(o1);
    unsigned cb2 = dGeomGetCategoryBits(o2);
    if ((cb1 == 0x02) || (cb2 == 0x02))
        return;

    dBodyID b1 = dGeomGetBody(o1);
    dBodyID b2 = dGeomGetBody(o2);
    /* Skip collision between connected bodies (adjacent board segments) */
    if (b1 && b2 && dAreConnectedExcluding(b1, b2, dJointTypeContact))
        return;

    dContact c[8];
    int n = dCollide(o1, o2, 8, &c[0].geom, sizeof(dContact));

    /* Find the board body to get its forward direction */
    dBodyID board_b = NULL;
    for (int s = 0; s < NUM_SEG; s++) {
        if (b1 == seg[s].body || b2 == seg[s].body) {
            board_b = (b1 == seg[s].body) ? b1 : b2;
            break;
        }
    }
    for (int i = 0; i < n; i++) {
        c[i].surface.mode = dContactSoftCFM | dContactSoftERP | dContactApprox1;
        c[i].surface.mu = 0.08;  /* snow friction */
        c[i].surface.soft_cfm = 0.008;
        c[i].surface.soft_erp = 0.3;

        dJointID j = dJointCreateContact(world, contacts, &c[i]);
        dJointAttach(j, b1, b2);
    }
}

void snow_init(float gravity) {
    dInitODE();
    world = dWorldCreate();
    space = dHashSpaceCreate(0);
    contacts = dJointGroupCreate(0);
    dWorldSetGravity(world, 0, gravity, 0);
    dWorldSetCFM(world, 1e-5);
    dWorldSetERP(world, 0.8);
    dWorldSetLinearDamping(world, 0.005);
    dWorldSetAngularDamping(world, 0.15);  /* keep yaw/tumble in check */
    dWorldSetQuickStepNumIterations(world, 60);
    spray_count = 0;
    spray_head = 0;
}

void snow_set_heightfield(float *data, int w, int h, float sx, float sz, float hmin, float hmax) {
    hf_data = data; hf_w = w; hf_h = h;
    hf_sx = sx; hf_sz = sz;

    int nv = w * h;
    tri_verts = (float *)malloc(nv * 3 * sizeof(float));
    for (int zi = 0; zi < h; zi++)
        for (int xi = 0; xi < w; xi++) {
            int vi = (zi * w + xi) * 3;
            tri_verts[vi+0] = (float)xi / (w-1) * sx;
            tri_verts[vi+1] = data[zi * w + xi];
            tri_verts[vi+2] = (float)zi / (h-1) * sz;
        }

    int cells = (w-1) * (h-1);
    int ni = cells * 6;
    tri_indices = (dTriIndex *)malloc(ni * sizeof(dTriIndex));
    int idx = 0;
    for (int zi = 0; zi < h-1; zi++)
        for (int xi = 0; xi < w-1; xi++) {
            int i = zi * w + xi;
            /* TEST: reverted winding */
            tri_indices[idx++] = i;
            tri_indices[idx++] = i + 1;
            tri_indices[idx++] = i + w;
            tri_indices[idx++] = i + 1;
            tri_indices[idx++] = i + w + 1;
            tri_indices[idx++] = i + w;
        }

    terrain_mesh_data = dGeomTriMeshDataCreate();
    dGeomTriMeshDataBuildSingle(terrain_mesh_data,
        tri_verts, 3*sizeof(float), nv,
        tri_indices, ni, 3*sizeof(dTriIndex));
    terrain_geom = dCreateTriMesh(space, terrain_mesh_data, NULL, NULL, NULL);
    dGeomSetCategoryBits(terrain_geom, 0x04);
    dGeomSetCollideBits(terrain_geom, 0x01);

    /* Side walls */
    dGeomID wall1 = dCreatePlane(space, 0, 0,  1, 0);
    dGeomID wall2 = dCreatePlane(space, 0, 0, -1, -sz);
    dGeomSetCategoryBits(wall1, 0x04); dGeomSetCollideBits(wall1, 0x01);
    dGeomSetCategoryBits(wall2, 0x04); dGeomSetCollideBits(wall2, 0x01);
}

void snow_create_board(float bl, float bw, float bt, float mass,
                       float x, float y, float z, float heading) {
    board_length = bl;
    board_width = bw;
    board_thick = bt;

    float seg_len = bl / NUM_SEG;
    float seg_mass = mass / NUM_SEG;
    dMatrix3 R;
    dRFromAxisAndAngle(R, 0, 1, 0, heading);

    /* Create 8 box segments along board length.
     * Each segment spawns at its local terrain height + small gap so whole
     * board lands simultaneously without asymmetric landing torque. */
    for (int i = 0; i < NUM_SEG; i++) {
        float offset = -bl/2 + seg_len/2 + i * seg_len;
        float sx = x + R[0]*offset;
        float sz_seg = z + R[8]*offset;
        /* Use local terrain height rather than uniform y — keeps board aligned to slope. */
        float th = terrain_height(sx, sz_seg);
        float sy = th + (y - terrain_height(x, z));  /* preserve offset from spawn y */

        seg[i].body = dBodyCreate(world);
        dBodySetPosition(seg[i].body, sx, sy, sz_seg);
        dBodySetRotation(seg[i].body, R);

        /* Bindings (seg[2], seg[5]) carry rider mass = 75kg total, split 37.5 each.
         * This keeps the "rider" center of mass at the board surface,
         * eliminating the pendulum destabilization we saw earlier. */
        float this_mass = seg_mass;
        if (has_rider && (i == 2 || i == 5)) this_mass += 34.5f;  /* 69kg across both bindings */

        dMass m;
        dMassSetBoxTotal(&m, this_mass, seg_len, bt, bw);
        dBodySetMass(seg[i].body, &m);

        seg[i].geom = dCreateBox(space, seg_len, bt, bw);
        dGeomSetBody(seg[i].geom, seg[i].body);
        dGeomSetCategoryBits(seg[i].geom, 0x01);
        dGeomSetCollideBits(seg[i].geom, 0x01);
        seg[i].half_len = seg_len / 2;
    }

    /* Hinge joints between consecutive segments — near-rigid */
    for (int i = 0; i < NUM_JOINT; i++) {
        seg_joint[i] = dJointCreateHinge(world, 0);
        dJointAttach(seg_joint[i], seg[i].body, seg[i+1].body);

        /* Anchor between adjacent segments — average their positions */
        const dReal *pi = dBodyGetPosition(seg[i].body);
        const dReal *pj = dBodyGetPosition(seg[i+1].body);
        float ax = (pi[0] + pj[0]) * 0.5f;
        float ay = (pi[1] + pj[1]) * 0.5f;
        float az_ = (pi[2] + pj[2]) * 0.5f;
        dJointSetHingeAnchor(seg_joint[i], ax, ay, az_);
        dJointSetHingeAxis(seg_joint[i], R[2], R[6], R[10]);  /* lateral axis */

        /* Stiff but allowing small flex */
        dJointSetHingeParam(seg_joint[i], dParamLoStop, -0.02);
        dJointSetHingeParam(seg_joint[i], dParamHiStop,  0.02);
        dJointSetHingeParam(seg_joint[i], dParamStopERP, 0.95);
        dJointSetHingeParam(seg_joint[i], dParamStopCFM, 1e-5);
    }

    /* Rider is visual-only now — 75kg mass is already baked into bindings above.
     * No physics bodies for rider. Perl renders it kinematically from board state. */
}

void snow_set_rider(float fore_aft, float lean) {
    rider_fore_aft = fore_aft;
    if (rider_fore_aft < -1) rider_fore_aft = -1;
    if (rider_fore_aft > 1) rider_fore_aft = 1;
    rider_lean = lean;
    if (rider_lean < -1) rider_lean = -1;
    if (rider_lean > 1) rider_lean = 1;
}

void snow_step(float dt) {
    /* Center segment for reference */
    const dReal *cpos = dBodyGetPosition(seg[3].body);
    const dReal *cvel = dBodyGetLinearVel(seg[3].body);
    const dReal *Rc = dBodyGetRotation(seg[3].body);

    current_speed = sqrt(cvel[0]*cvel[0] + cvel[1]*cvel[1] + cvel[2]*cvel[2]);

    /* Edge angle from center segment orientation vs terrain normal */
    {
        float up_x = Rc[1], up_y = Rc[5], up_z = Rc[9];
        float fwd_x = Rc[0], fwd_y = Rc[4], fwd_z = Rc[8];
        float hx1 = terrain_height(cpos[0]+0.5, cpos[2]);
        float hx0 = terrain_height(cpos[0]-0.5, cpos[2]);
        float hz1 = terrain_height(cpos[0], cpos[2]+0.5);
        float hz0 = terrain_height(cpos[0], cpos[2]-0.5);
        float tnx = -(hx1-hx0), tny = 1.0, tnz = -(hz1-hz0);
        float tnl = sqrt(tnx*tnx + tny*tny + tnz*tnz);
        tnx /= tnl; tny /= tnl; tnz /= tnl;
        float cx = up_y*tnz - up_z*tny;
        float cy = up_z*tnx - up_x*tnz;
        float cz = up_x*tny - up_y*tnx;
        edge_angle = cx*fwd_x + cy*fwd_y + cz*fwd_z;
        if (edge_angle > 1) edge_angle = 1;
        if (edge_angle < -1) edge_angle = -1;
    }

    /* Rider lean → torque on center segment around board forward axis (roll).
     * This simulates shifting weight edge-to-edge without needing a physics rider. */
    if (has_rider && rider_lean != 0) {
        float fx = Rc[0], fy = Rc[4], fz = Rc[8];  /* board forward axis */
        float torque = rider_lean * 40.0;
        dBodyAddTorque(seg[3].body, fx*torque, fy*torque, fz*torque);
    }
    /* Rider fore/aft → shift weight from rear binding (seg[2]) to front (seg[5]) */
    if (has_rider && rider_fore_aft != 0) {
        float force_y = rider_fore_aft * 30.0;
        dBodyAddForce(seg[5].body, 0, -force_y, 0);  /* push front down when fore_aft>0 */
        dBodyAddForce(seg[2].body, 0,  force_y, 0);
    }

    /* Spray from edge contact */
    if (current_speed > 0.3 && fabs(edge_angle) > 0.2) {
        float right_x = Rc[2], right_z = Rc[10];
        float sign = edge_angle > 0 ? 1.0 : -1.0;
        float sx = cpos[0] - right_x * board_width * 0.5 * sign;
        float sz = cpos[2] - right_z * board_width * 0.5 * sign;
        emit_spray(sx, cpos[1], sz,
                   -right_x * sign * current_speed * 0.4,
                   0,
                   -right_z * sign * current_speed * 0.4,
                   current_speed * fabs(edge_angle));
    }

    /* Update spray particles */
    for (int i = 0; i < spray_count; i++) {
        int idx = (spray_head - spray_count + i + MAX_SPRAY) % MAX_SPRAY;
        spray[idx].x += spray[idx].vx * dt;
        spray[idx].y += spray[idx].vy * dt;
        spray[idx].z += spray[idx].vz * dt;
        spray[idx].vy -= 1.5 * dt;
        spray[idx].vx *= 0.98; spray[idx].vz *= 0.98;
        spray[idx].age += dt;
        spray[idx].size += dt * 0.02;
    }
    while (spray_count > 0) {
        int oldest = (spray_head - spray_count + MAX_SPRAY) % MAX_SPRAY;
        if (spray[oldest].age >= spray[oldest].life) spray_count--;
        else break;
    }

    /* Anti-tunneling safety net: only for catastrophic tunneling (>1m below) */
    for (int i = 0; i < NUM_SEG; i++) {
        const dReal *sp = dBodyGetPosition(seg[i].body);
        float th = terrain_height(sp[0], sp[2]);
        if (sp[1] < th - 1.0) {
            dBodySetPosition(seg[i].body, sp[0], th + 0.1, sp[2]);
            const dReal *sv = dBodyGetLinearVel(seg[i].body);
            if (sv[1] < 0)
                dBodySetLinearVel(seg[i].body, sv[0], 0, sv[2]);
        }
    }

    /* Physics substep for stability */
    float substep = 1.0/120.0;
    int steps = (int)(dt / substep);
    if (steps < 1) steps = 1;
    if (steps > 4) steps = 4;
    for (int s = 0; s < steps; s++) {
        dSpaceCollide(space, 0, &near_cb);
        dWorldQuickStep(world, dt / steps);
        dJointGroupEmpty(contacts);
    }
}

/* Get all 8 segment states: 8 * 7 = 56 floats (x,y,z,qx,qy,qz,qw each) */
void snow_get_segments(float *out) {
    for (int i = 0; i < NUM_SEG; i++) {
        const dReal *p = dBodyGetPosition(seg[i].body);
        const dReal *q = dBodyGetQuaternion(seg[i].body);
        int o = i * 7;
        out[o+0]=p[0]; out[o+1]=p[1]; out[o+2]=p[2];
        out[o+3]=q[1]; out[o+4]=q[2]; out[o+5]=q[3]; out[o+6]=q[0];
    }
}

/* Aggregate board info: speed, edge_angle = 2 floats */
void snow_get_board_info(float *out) {
    out[0] = current_speed;
    out[1] = edge_angle;
}

/* Rider state: lower(pos3+quat4) + upper(pos3+quat4) = 14 floats */
void snow_get_rider(float *out) {
    if (!lower_body || !upper_body) {
        for (int i = 0; i < 14; i++) out[i] = 0;
        return;
    }
    const dReal *lp = dBodyGetPosition(lower_body);
    const dReal *lq = dBodyGetQuaternion(lower_body);
    out[0]=lp[0]; out[1]=lp[1]; out[2]=lp[2];
    out[3]=lq[1]; out[4]=lq[2]; out[5]=lq[3]; out[6]=lq[0];
    const dReal *up = dBodyGetPosition(upper_body);
    const dReal *uq = dBodyGetQuaternion(upper_body);
    out[7]=up[0]; out[8]=up[1]; out[9]=up[2];
    out[10]=uq[1]; out[11]=uq[2]; out[12]=uq[3]; out[13]=uq[0];
}

void snow_set_has_rider(int flag) { has_rider = flag; }

int snow_get_spray(float *out, int max) {
    int n = spray_count < max ? spray_count : max;
    for (int i = 0; i < n; i++) {
        int idx = (spray_head - spray_count + i + MAX_SPRAY) % MAX_SPRAY;
        float alpha = 1.0 - spray[idx].age / spray[idx].life;
        out[i*5+0] = spray[idx].x;
        out[i*5+1] = spray[idx].y;
        out[i*5+2] = spray[idx].z;
        out[i*5+3] = alpha * alpha;
        out[i*5+4] = spray[idx].size;
    }
    return n;
}

void snow_cleanup(void) {
    if (terrain_mesh_data) { dGeomTriMeshDataDestroy(terrain_mesh_data); terrain_mesh_data = NULL; }
    dJointGroupDestroy(contacts);
    dSpaceDestroy(space);
    dWorldDestroy(world);
    dCloseODE();
    free(tri_verts); tri_verts = NULL;
    free(tri_indices); tri_indices = NULL;
    world = 0; space = 0; contacts = 0;
    terrain_geom = 0;
    for (int i = 0; i < NUM_SEG; i++) { seg[i].body = 0; seg[i].geom = 0; }
    for (int i = 0; i < NUM_JOINT; i++) seg_joint[i] = 0;
    lower_body = 0; upper_body = 0; lower_geom = 0; upper_geom = 0;
    ankle_front = 0; ankle_rear = 0; hip_joint = 0; hip_motor = 0;
}
