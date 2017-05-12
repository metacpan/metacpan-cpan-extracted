drop trigger node_delete_trigger on node;
delete from build_vars;
delete from choicelist;
delete from distro;
delete from keeplist;
delete from license;
delete from node;
delete from node_distro;
delete from node_license;
delete from node_parent;
delete from provides;
create trigger node_delete_trigger before delete on node 
    for each row execute procedure node_dependencies_delete();
