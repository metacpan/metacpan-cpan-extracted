# NAME

Global::IPC::StaticVariable - A module can alloc 512MB Sysv IPC shared memory for perl

# SYNOPSIS

    use Global::IPC::StaticVariable;

# DESCRIPTION

Global::IPC::StaticVariable is a module which can alloc 512MB Sysv IPC shared memory for perl.  
You can use it to delivery contents, or use it as a job queue.  
It can be updated with strings, or append into it, or get contents and clear it.  

And all of the updating operation is under the mutex lock for data safety.  

# USAGE

\# 0. use Global::IPC::StaticVariable;  

    use Global::IPC::StaticVariable qw/var_create var_destory var_read var_update var_append var_getreset var_length/;  
    

\# 1. create a new global sysv ipc id  

      my $id = var_create();  
    

\# 2. update a string (with lock)  

      var_update($id, "content");  
    

\# 3. read by id (no lock)  
\# you can use var\_update and var\_read at different process  

      my $content = var_read($id);  
    

\# 4. append string (with lock)  
\# you can use this as a jobqueue  

      var_append($id, ' append');
    

\# 5. get length of var  

      my $len = var_length($id);  
    

\# 6. getreset  
\# get and reset pointer with lock, use like as a jobqueue  

      var_getreset($id);  
    

\# 7. destory memory  

      var_destory($id);  
    

# LICENSE

Copyright (C) itsusony. FreakOut.  
MIT License

# AUTHOR

itsusony <itsusony@fout.jp>
