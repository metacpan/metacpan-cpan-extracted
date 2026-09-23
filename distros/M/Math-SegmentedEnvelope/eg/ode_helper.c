/*
 * ODE physics helper for Perl FFI::Platypus
 * Minimal wrapper: world, bodies, terrain heightfield, step, read positions
 *
 * Build: cc -shared -fPIC -O2 -o libode_helper.so ode_helper.c -lode -lm
 */
#include <ode/ode.h>
#include <math.h>
#include <string.h>

#define MAX_BODIES 64
#define MAX_CONTACTS 8

static dWorldID world;
static dSpaceID space;
static dJointGroupID contact_group;
static dGeomID ground_plane;

static struct {
    dBodyID body;
    dGeomID geom;
    int type;  /* 0=box, 1=sphere */
    float size;
    float r, g, b;
} bodies[MAX_BODIES];
static int num_bodies = 0;

/* Heightfield data */
static float *hfield_data = NULL;
static int hfield_w = 0, hfield_h = 0;
static float hfield_sx = 1, hfield_sz = 1;
static dGeomID hfield_geom = NULL;

/* Heightfield callback */
static dReal heightfield_cb(void *data, int x, int z) {
    if (!hfield_data) return 0;
    if (x < 0) x = 0; if (x >= hfield_w) x = hfield_w - 1;
    if (z < 0) z = 0; if (z >= hfield_h) z = hfield_h - 1;
    return (dReal)hfield_data[z * hfield_w + x];
}

/* Collision callback */
static void near_callback(void *data, dGeomID o1, dGeomID o2) {
    dBodyID b1 = dGeomGetBody(o1);
    dBodyID b2 = dGeomGetBody(o2);
    if (b1 && b2 && dAreConnectedExcluding(b1, b2, dJointTypeContact)) return;

    dContact contacts[MAX_CONTACTS];
    int n = dCollide(o1, o2, MAX_CONTACTS, &contacts[0].geom, sizeof(dContact));
    for (int i = 0; i < n; i++) {
        contacts[i].surface.mode = dContactBounce | dContactSoftCFM | dContactSoftERP
                                 | dContactSlip1 | dContactSlip2;
        contacts[i].surface.mu = 0.15;          /* low friction: icy/snowy surface */
        contacts[i].surface.bounce = 0.05;       /* almost no bounce: snow absorbs */
        contacts[i].surface.bounce_vel = 0.01;
        contacts[i].surface.soft_cfm = 0.01;    /* soft: snow compresses */
        contacts[i].surface.soft_erp = 0.3;     /* slow correction: sinks a bit */
        contacts[i].surface.slip1 = 0.05;       /* lateral slip */
        contacts[i].surface.slip2 = 0.05;
        dJointID c = dJointCreateContact(world, contact_group, &contacts[i]);
        dJointAttach(c, b1, b2);
    }
}

void ode_init(float grav) {
    dInitODE();
    world = dWorldCreate();
    space = dHashSpaceCreate(0);
    contact_group = dJointGroupCreate(0);
    dWorldSetGravity(world, 0, grav, 0);
    dWorldSetCFM(world, 1e-5);
    dWorldSetERP(world, 0.8);
    dWorldSetLinearDamping(world, 0.005);   /* snow drag */
    dWorldSetAngularDamping(world, 0.01);   /* rotational drag */
    dWorldSetAutoDisableFlag(world, 1);
    dWorldSetAutoDisableLinearThreshold(world, 0.01);
    dWorldSetAutoDisableAngularThreshold(world, 0.01);
    dWorldSetAutoDisableSteps(world, 30);
    num_bodies = 0;
}

void ode_set_heightfield(float *data, int w, int h, float sx, float sz) {
    hfield_data = data;
    hfield_w = w; hfield_h = h;
    hfield_sx = sx; hfield_sz = sz;

    /* Find actual height bounds */
    float hmin = data[0], hmax = data[0];
    for (int i = 1; i < w * h; i++) {
        if (data[i] < hmin) hmin = data[i];
        if (data[i] > hmax) hmax = data[i];
    }

    dHeightfieldDataID hd = dGeomHeightfieldDataCreate();
    dGeomHeightfieldDataBuildCallback(hd, NULL, heightfield_cb,
        sx, sz, w, h, 1.0, 0.0, 0.0, 0);
    dGeomHeightfieldDataSetBounds(hd, hmin, hmax + 0.1);
    hfield_geom = dCreateHeightfield(space, hd, 1);
    /* ODE heightfield is centered at its position.
     * We set position to (sx/2, 0, sz/2) so it spans [0,sx] x [0,sz] in world. */
    dGeomSetPosition(hfield_geom, sx/2, 0, sz/2);
}

int ode_add_box(float x, float y, float z, float size, float mass,
                float r, float g, float b) {
    if (num_bodies >= MAX_BODIES) return -1;
    int idx = num_bodies++;
    bodies[idx].type = 0;
    bodies[idx].size = size;
    bodies[idx].r = r; bodies[idx].g = g; bodies[idx].b = b;

    bodies[idx].body = dBodyCreate(world);
    dBodySetPosition(bodies[idx].body, x, y, z);
    /* Random initial rotation */
    dMatrix3 R;
    dRFromEulerAngles(R, dRandReal()*3.14, dRandReal()*3.14, dRandReal()*3.14);
    dBodySetRotation(bodies[idx].body, R);

    dMass m;
    dMassSetBoxTotal(&m, mass, size, size, size);
    dBodySetMass(bodies[idx].body, &m);

    bodies[idx].geom = dCreateBox(space, size, size, size);
    dGeomSetBody(bodies[idx].geom, bodies[idx].body);
    return idx;
}

int ode_add_sphere(float x, float y, float z, float radius, float mass,
                   float r, float g, float b) {
    if (num_bodies >= MAX_BODIES) return -1;
    int idx = num_bodies++;
    bodies[idx].type = 1;
    bodies[idx].size = radius;
    bodies[idx].r = r; bodies[idx].g = g; bodies[idx].b = b;

    bodies[idx].body = dBodyCreate(world);
    dBodySetPosition(bodies[idx].body, x, y, z);

    dMass m;
    dMassSetSphereTotal(&m, mass, radius);
    dBodySetMass(bodies[idx].body, &m);

    bodies[idx].geom = dCreateSphere(space, radius);
    dGeomSetBody(bodies[idx].geom, bodies[idx].body);
    return idx;
}

void ode_step(float dt) {
    dSpaceCollide(space, 0, &near_callback);
    dWorldQuickStep(world, dt);
    dJointGroupEmpty(contact_group);
}

int ode_get_num_bodies(void) { return num_bodies; }

/* Get body state: x,y,z, rx,ry,rz,rw (quaternion), type, size, r,g,b = 12 floats */
void ode_get_body(int idx, float *out) {
    if (idx < 0 || idx >= num_bodies) return;
    const dReal *pos = dBodyGetPosition(bodies[idx].body);
    const dReal *quat = dBodyGetQuaternion(bodies[idx].body);
    out[0] = pos[0]; out[1] = pos[1]; out[2] = pos[2];
    out[3] = quat[1]; out[4] = quat[2]; out[5] = quat[3]; out[6] = quat[0]; /* xyzw */
    out[7] = bodies[idx].type;
    out[8] = bodies[idx].size;
    out[9] = bodies[idx].r; out[10] = bodies[idx].g; out[11] = bodies[idx].b;
}

void ode_cleanup(void) {
    dJointGroupDestroy(contact_group);
    dSpaceDestroy(space);
    dWorldDestroy(world);
    dCloseODE();
    num_bodies = 0;
}
