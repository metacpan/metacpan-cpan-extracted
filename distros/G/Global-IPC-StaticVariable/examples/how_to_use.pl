#! /usr/bin/env perl
use strict;
use warnings;

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
