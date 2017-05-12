/* distro */
create table distro (
    distro_id       serial,
    board           varchar(64),
    distro_name     varchar(64),
    description     text,
    root_node_id    oid not null,
    primary key     (distro_id)
);

/* a node may belong to more than one distro */
create table node_distro (
    node_id         oid not null,
    distro_id       oid not null
);

create index nd_node_index on node_distro(node_id);
create index nd_distro_index on node_distro (distro_id);

/* node */
create table node (
    node_id         serial,
    node_class      varchar(16) not null,
    node_name       varchar(64) not null,

    value_type      varchar(16),
    range           int[],
    default_value   varchar(16),
    value           varchar(16),

    help            text,
    prompt          text,

    srpm            varchar(32),
    specpatch       varchar(32),

    static_size     int[]  default '{0, 0}',
    min_dynamic_size int[] default '{0, 0}',
    storage_size    int[]  default '{0, 0}',
    startup_time    int[]  default '{0, 0}',

    conflicts       varchar(64),
    requires_type   varchar(16),
    requires        text,
    if              text,

    primary key     (node_id)
);

create index node_class_index on node (node_class);
create index node_name_index  on node (node_name);

/* text of all the licenses */
create table license (
    license_id      serial,
    name            varchar(32) unique,
    is_free         bool,
    restrictions    text,
    primary key     (license_id)
);

/* 
All the licenses that apply to a node.  Let's just specify licenses at the
component level for now.
*/
create table node_license (
    node_id         oid,
    license_id      oid
);

/* entries that go in a .spec file's %files section */
create table keeplist (
    node_id         oid not null,
    entry           varchar(256),
    primary key     (node_id, entry)
);

/* used in linux.ecd; I'm not sure for what */
create table choicelist (
    node_id         oid not null,
    entry           varchar(64),
    primary key     (node_id, entry)
);

/* symbols used during dependency and conflict resolution */
create table provides (
    node_id         oid not null,
    entry           varchar(64),
    primary key     (node_id, entry)
);

/* variables that get substituted just prior to rpm -bi */
create table build_vars (
    node_id         oid not null,
    name            varchar(64),
    value           varchar(64),
    primary key     (node_id, name)
);

/* represents the node hierarchy */
create table node_parent (
    node_id         oid not null,
    parent_id       oid not null
);

create index node_parent_index on node_parent (parent_id);

create function node_aggregates_delete(oid) returns opaque as
    'declare
        id alias for $1;
    begin
        delete from keeplist     where node_id = id;
        delete from choicelist   where node_id = id;
        delete from provides     where node_id = id;
        delete from build_vars   where node_id = id;
        delete from node_license where node_id = id;
        return OLD; 
    end;'
    language 'plpgsql';

/* this reminds me of pascal */
create function node_dependencies_delete() returns opaque as
    'declare
        id oid;
    begin
        id := OLD.node_id;
        select node_aggregates_delete(id);
        delete from node where node_id in 
            (select node_id from node_parent where parent_id = id);
        delete from node_parent  where parent_id = id;
        return OLD; 
    end;'
    language 'plpgsql';

/* when a node is deleted, delete its dependencies first */
create trigger node_delete_trigger before delete on node 
    for each row execute procedure node_dependencies_delete();

/* $Id: pg_schema.sql,v 1.5 2001/02/21 20:56:00 beppu Exp $ */
