REM prepare database for Genezzo::Contrib::Clustered
REM @havok.sql and @syshook.sql first
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, args, owner, creationdate, version) values (1000, 'Genezzo::BufCa::BCFile', '_filereadblock', 'ReadBlock_Hook', 'oo_require', 'Genezzo::Contrib::Clustered', 'ReadBlock', 'SYSTEM', '2005-07-25T12:12', '1');
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, args, owner, creationdate, version) values (1001, 'Genezzo::BufCa::DirtyScalar', 'STORE', 'DirtyBlock_Hook', 'oo_require', 'Genezzo::Contrib::Clustered', 'DirtyBlock', 'SYSTEM', '2005-07-25T12:12', '1');
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, args, owner, creationdate, version) values (1002, 'Genezzo::GenDBI', 'Kgnz_Commit', 'Commit_Hook', 'oo_require', 'Genezzo::Contrib::Clustered', 'Commit', 'SYSTEM', '2005-07-25T12:12', '1');
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, args, owner, creationdate, version) values (1003, 'Genezzo::GenDBI', 'Kgnz_Rollback', 'Rollback_Hook', 'oo_require', 'Genezzo::Contrib::Clustered', 'Rollback', 'SYSTEM', '2005-07-25T12:12', '1');
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, args, owner, creationdate, version) values (1003, 'Genezzo::GenDBI', 'Kgnz_Execute', 'Execute_Hook', 'oo_require', 'Genezzo::Contrib::Clustered', 'Execute', 'SYSTEM', '2005-07-25T12:12', '1');
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, args, owner, creationdate, version) values (1004, 'Genezzo::BufCa::BCFile', '_init_filewriteblock', '_init_fwb_Hook', 'oo_require', 'Genezzo::Contrib::Clustered', '_init_filewriteblock', 'SYSTEM', '2005-07-25T12:12', '1');
commit;
shutdown;
REM restart gendba.pl from command line so Havok routines will be redefined
quit;

