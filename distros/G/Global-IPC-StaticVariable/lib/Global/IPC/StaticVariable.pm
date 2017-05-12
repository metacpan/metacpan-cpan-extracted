package Global::IPC::StaticVariable;
use 5.008001;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.015";

our @EXPORT_OK = qw( 
    var_create
    var_update
    var_append
    var_read
    var_destory
    var_getreset
    var_length
);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Global::IPC::StaticVariable - A module can alloc 512MB Sysv IPC shared memory for perl

=head1 SYNOPSIS

    use Global::IPC::StaticVariable;

=head1 DESCRIPTION

Global::IPC::StaticVariable is a module which can alloc 512MB Sysv IPC shared memory for perl.  
You can use it to delivery contents, or use it as a job queue.  
It can be updated with strings, or append into it, or get contents and clear it.  
  
And all of the updating operation is under the mutex lock for data safety.  

=head1 USAGE

# 0. use Global::IPC::StaticVariable;  
  
  use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update var_append var_getreset var_length/;  
  
# 1. create a new global sysv ipc id  
  
    my $id = var_create();  
  
# 2. update a string (with lock)  
  
    var_update($id, "content");  
  
# 3. read by id (no lock)  
# you can use var_update and var_read at different process  
  
    my $content = var_read($id);  
  
# 4. append string (with lock)  
# you can use this as a jobqueue  
  
    var_append($id, ' append');
  
# 5. get length of var  
  
    my $len = var_length($id);  
  
# 6. getreset  
# get and reset pointer with lock, use like as a jobqueue  
  
    var_getreset($id);  
  
# 7. destory memory  
  
    var_destory($id);  
  
=head1 LICENSE

Copyright (C) itsusony. FreakOut.  
MIT License

=head1 AUTHOR

itsusony E<lt>itsusony@fout.jpE<gt>

=cut

