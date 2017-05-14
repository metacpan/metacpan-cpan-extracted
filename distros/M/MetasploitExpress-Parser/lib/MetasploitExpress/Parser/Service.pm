# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::Service;
{
    use Object::InsideOut;

    my @created_at : Field : Arg(created_at) : Get(created_at);
    my @host_id : Field : Arg(host_id) : Get(host_id);
    my @id : Field : Arg(id) : Get(id);
    my @name : Field : Arg(name) : Get(name);
    my @module : Field : Arg(module) : Get(module);
    my @info : Field : Arg(info) : Get(info);
    my @port : Field : Arg(port) : Get(port);
    my @proto : Field : Arg(proto) : Get(proto);
    my @state : Field : Arg(state) : Get(state);
    my @updated_at : Field : Arg(updated_at) : Get(updated_at);
}
1;
