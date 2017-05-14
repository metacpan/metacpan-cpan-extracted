# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::Host;
{
    use Object::InsideOut;

    my @address : Field : Arg(address) : Get(address);
    my @address6 : Field : Arg(address6) : Get(address6);
    my @arch : Field : Arg(arch) : Get(arch);
    my @comments : Field : Arg(comments) : Get(comments);
    my @comm : Field : Arg(comm) : Get(comm);
    my @created_at : Field : Arg(created_at) : Get(created_at);
    my @id : Field : Arg(id) : Get(id);
    my @info : Field : Arg(info) : Get(info);
    my @mac : Field : Arg(mac) : Get(mac);
    my @name : Field : Arg(name) : Get(name);
    my @os_flavor : Field : Arg(os_flavor) : Get(os_flavor);
    my @os_name : Field : Arg(os_name) : Get(os_name);
    my @os_lang : Field : Arg(os_lang) : Get(os_lang);
    my @os_sp : Field : Arg(os_sp) : Get(os_sp);
    my @purpose : Field : Arg(purpose) : Get(purpose);
    my @state : Field : Arg(state) : Get(state);
    my @updated_at : Field : Arg(updated_at) : Get(updated_at);
    my @workspace_id : Field : Arg(workspace_id) : Get(workspace_id);

    ## TODO
    # add services
    # add vulns
    # add notes
}
1;
