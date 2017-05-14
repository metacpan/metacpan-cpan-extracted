# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::Report;
{
    use Object::InsideOut;

    my @created_at : Field : Arg(created_at) : Get(created_at);
    my @created_by : Field : Arg(created_by) : Get(created_by);
    my @downloaded_at : Field : Arg(downloaded_at) : Get(downloaded_at);
    my @id : Field : Arg(id) : Get(id);
    my @path : Field : Arg(path) : Get(path);
    my @rtype : Field : Arg(rtype) : Get(rtype);
    my @options : Field : Arg(options) : Get(options);
    my @updated_at : Field : Arg(updated_at) : Get(updated_at);
    my @workspace_id : Field : Arg(workspace_id) : Get(workspace_id);
}
1;
