# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::Event;
{
    use Object::InsideOut;

    my @created_at : Field : Arg(created_at) : Get(created_at);
    my @critical : Field : Arg(critical) : Get(critical);
    my @host_id : Field : Arg(host_id) : Get(host_id);
    my @id : Field : Arg(id) : Get(id);
    my @name : Field : Arg(name) : Get(name);
    my @seen : Field : Arg(seen) : Get(seen);
    my @updated_at : Field : Arg(updated_at) : Get(updated_at);
    my @workspace_id : Field : Arg(workspace_id) : Get(workspace_id);
}
1;
