# $Id: Host.pm 18 2008-05-05 23:55:18Z jabra $
package MetasploitExpress::Parser::Task;
{
    use Object::InsideOut;

    my @completed_at : Field : Arg(completed_at) : Get(completed_at);
    my @created_at : Field : Arg(created_at) : Get(created_at);
    my @created_by : Field : Arg(created_by) : Get(created_by);
    my @description : Field : Arg(description) : Get(description);
    my @error : Field : Arg(error) : Get(error);
    my @id : Field : Arg(id) : Get(id);
    my @module : Field : Arg(module) : Get(module);
    my @path : Field : Arg(path) : Get(path);
    my @progress : Field : Arg(progress) : Get(progress);
    my @result : Field : Arg(result) : Get(result);
    my @updated_at : Field : Arg(updated_at) : Get(updated_at);
    my @workspace_id : Field : Arg(workspace_id) : Get(workspace_id);
}
1;
