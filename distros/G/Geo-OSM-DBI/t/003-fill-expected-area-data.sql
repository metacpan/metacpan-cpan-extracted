
create table nod_id_expected (id integer primary key); -- {
--
insert into nod_id_expected values ( 10);
insert into nod_id_expected values ( 11);
insert into nod_id_expected values ( 12);
insert into nod_id_expected values ( 13);
--
insert into nod_id_expected values ( 20);
insert into nod_id_expected values ( 23);
insert into nod_id_expected values ( 22);
insert into nod_id_expected values ( 21);
--
insert into nod_id_expected values ( 30);
insert into nod_id_expected values ( 31);
insert into nod_id_expected values ( 32);
insert into nod_id_expected values ( 33);
insert into nod_id_expected values ( 34);
insert into nod_id_expected values ( 35);
insert into nod_id_expected values ( 36);
insert into nod_id_expected values ( 37);
--
insert into nod_id_expected values ( 40);
insert into nod_id_expected values ( 41);
--
insert into nod_id_expected values ( 50);
--
insert into nod_id_expected values ( 60);
insert into nod_id_expected values ( 61);
insert into nod_id_expected values ( 62);
--
insert into nod_id_expected values ( 70);
insert into nod_id_expected values ( 71);
--
insert into nod_id_expected values ( 80);
insert into nod_id_expected values ( 81);
insert into nod_id_expected values ( 82);
--
insert into nod_id_expected values ( 90);
--



------------------------------------------------- -- }
create table nod_way_expected (way_id, nod_id, order_); -- {
insert into nod_way_expected values (  2, 10, 0);
insert into nod_way_expected values (  2, 11, 1);
insert into nod_way_expected values (  2, 12, 2);
insert into nod_way_expected values (  2, 13, 3);
insert into nod_way_expected values (  2, 10, 4);

insert into nod_way_expected values (  3, 20, 0);
insert into nod_way_expected values (  3, 21, 1);
insert into nod_way_expected values (  3, 22, 2);
insert into nod_way_expected values (  3, 23, 3);
insert into nod_way_expected values (  3, 20, 4);

insert into nod_way_expected values (  4, 30, 0);
insert into nod_way_expected values (  4, 31, 1);
insert into nod_way_expected values (  4, 32, 2);
insert into nod_way_expected values (  4, 33, 3);
insert into nod_way_expected values (  4, 34, 4);
insert into nod_way_expected values (  4, 35, 5);
insert into nod_way_expected values (  4, 36, 6);
insert into nod_way_expected values (  4, 37, 7);
insert into nod_way_expected values (  4, 30, 8);

insert into nod_way_expected values (  5, 40, 0);
insert into nod_way_expected values (  5, 41, 1);

insert into nod_way_expected values (  6, 62, 0);
insert into nod_way_expected values (  6, 61, 1);
insert into nod_way_expected values (  6, 60, 2);

insert into nod_way_expected values (  7, 62, 0);
insert into nod_way_expected values (  7, 70, 1);
insert into nod_way_expected values (  7, 71, 2);
insert into nod_way_expected values (  7, 80, 3);

insert into nod_way_expected values (  8, 80, 0);
insert into nod_way_expected values (  8, 81, 1);
insert into nod_way_expected values (  8, 82, 2);

insert into nod_way_expected values (  9, 82, 0);
insert into nod_way_expected values (  9, 90, 1);
insert into nod_way_expected values (  9, 60, 2);

 -- }
create table rel_mem_expected (rel_of, order_, nod_id, way_id, rel_id, rol); -- {

insert into rel_mem_expected values (19, 0,   50, null, null, "Rel 19: node" );
insert into rel_mem_expected values (19, 1, null,    6, null, "Rel 19: South");
insert into rel_mem_expected values (19, 2, null,    7, null, "Rel 19: East" );
insert into rel_mem_expected values (19, 3, null,    8, null, "Rel 19: North");
insert into rel_mem_expected values (19, 4, null,    9, null, "Rel 19: West" );

-- }
create table tag_expected(nod_id, way_id, rel_id, key, val); -- {

insert into tag_expected values (   22, null, null, 'key-22-1'        , 'val-22-1'      );
insert into tag_expected values (   22, null, null, 'key-22-2'        , 'val-22-2'      );
insert into tag_expected values (   40, null, null, 'key-40-1'        , 'val-40-1'      );
insert into tag_expected values (   40, null, null, 'key-40-2'        , 'val-40-2'      );
insert into tag_expected values (   50, null, null, 'label'           , 'Relation 19'   );

insert into tag_expected values ( null,    2, null, 'building'        , 'yes'           );
insert into tag_expected values ( null,    2, null, 'addr:street'     , 'Foostr'        );
insert into tag_expected values ( null,    2, null, 'addr:housenumber', '42'            );
insert into tag_expected values ( null,    2, null, 'addr:postcode'   , '9999'          );
insert into tag_expected values ( null,    2, null, 'addr:city'       , 'Dorfikon'      );

insert into tag_expected values ( null,    3, null, 'building'        , 'house'         );

insert into tag_expected values ( null, null,   19, 'name'            , 'Relation 19'   );
insert into tag_expected values ( null, null,   19, 'key-rel-19'      , 'val-rel-19'    ); -- }
