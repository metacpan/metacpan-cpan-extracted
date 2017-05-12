package Lufs::Ram;

use strict;
no warnings;

use constant DR => 0040000;
use constant FL => 0100000;

sub init {
    my $self = shift;
    $self->{nodes} = [];
	$self->{config} = pop;
    $self->new_node('',DR|0755);
    $self->{pwd} = $self->{nodes}[0];
}

sub mount {
    my $self = shift;
}

sub umount {
    my $self = shift;
    # undef $self->{nodes};
}

sub abspath {
    my $self = shift;
    my $name = shift;
    $name =~ s{/\.$}{/};
    if ($name =~ /^\//) { return $name }
    $name =~ s{^\./}{/};
    if (!defined$self->{pwd}) {
        $self->{pwd} = $self->{nodes}[0];
    }
    if (ref($self->{pwd})) {
        return $self->{pwd}->fq_name."/$name";
    }
    else {
        return "$self->{pwd}/$name";
    }
}
 
sub new_node {
    my $self = shift;
    my ($name,$mode) = @_;
    my $node;
    if ($node = $self->lookup_name($name)) {
        return $node;
    }
    if ($name eq ''and!defined$self->{nodes}[0]) {
        $node = Lufs::Ram::Node->new($self,{f_name=>'',f_mode=>$mode});
        push @{$self->{nodes}}, $node;
    }
    else {
        $name = $self->abspath($name);
        $name =~ m/^(.*)?\/(.*?)$/;
        my ($host,$new) = ($1,$2);
        # $self->TRACE("split: name='$name' host='$host',new='$new'");
        my $parent;
        unless ($parent = $self->lookup_name($host)) {
            $self->TRACE("parent '$host' not found, cannot create node");
            return;
        }
        unless ($parent->is_dir) {
            $self->TRACE("parent '$host' isna dir, cannot create node");
            return;
        }
        $node = Lufs::Ram::Node->new($self,{f_name=>$new,f_mode=>$mode});
        $parent->add_node($node);
    }
}

sub new_ino {
    my $self = shift;
    ([sort{$b<=>$a}map {$_->f_ino} @{$self->{nodes}}]->[0]||0)+1;
}

sub lookup_name {
    my $self = shift;
    my $name = shift;
    $name = $self->abspath($name); $name =~ s{^/}{};
    if ($name eq '') { return $self->{nodes}[0] }
    my $node = $self->{nodes}[0];
    for (split/\//,$name) {
        my ($x) = $node->lookup_name($_);
        unless (ref($x)) {
            return;
        }
        $node = $x;
    }
    return $node;
}

sub lookup_ino {
    my $self = shift;
    my $ino = shift;
    $self->{nodes}[0]->lookup_ino($ino);
}

sub mkdir {
    my $self = shift;
    my $dir = shift;
    my $mode = shift;
    ref($self->new_node($dir,DR|$mode))=~/Node/;
}
 
sub rmdir {
    my $self = shift;
    my $dir = shift;
    my $node = $self->lookup_name($dir);
    unless (ref($node)) { return 0 }
    $node->is_dir || return 0;
    $node->is_empty || return 0;
    $node->parent->del_node($node);
    return 1;
}

sub unlink {
    my $self = shift;
    my $file = shift;
    my $node = $self->lookup_name($file) or return 0;
    $node->is_file || return 0;
    $node->parent->del_node($node);
    return 1;
}

sub create {
    my $self = shift;
    my ($file,$mode) = @_;
    ref($self->new_node($file,FL|$mode))=~/Node/;
}

sub readlink { 0 }
sub link { 0 }
sub symlink { 0 }

sub rename {
    my $self = shift;
    $self->TRACE("rename($_[0],$_[1])");
    return 0;
}

sub stat {
    my $self = shift;
    my $file = shift;
    my $node = $self->lookup_name($file) or return 0;
    my $ref = $node->get_attr;
    map { $_[0]->{$_} = $ref->{$_} } keys %{$ref};
    return 1;
}

sub readdir {
    my $self = shift;
    my $dir = shift;
    my $ref = shift;
    my $node = $self->lookup_name($dir);
    unless ($node) { return 0 }
    $node->is_dir || return 0;
    $self->{pwd} = $node;
    push @{$ref}, map { $_->f_name } @{$node->{nodes}};
    return 1;
}
 
sub open { 0 }

sub release { 1 }

sub read {
    my $self = shift;
    my $file = shift;
    my ($offset,$count) = (shift,shift);
    my $node = $self->lookup_name($file) or return -1;
    $node->is_file || return -1;
    my $str = $node->read($offset,$count);
    $_[0] = $str;
    return length($str);
}

sub write {
    my $self = shift;
    my $file = shift;
    my ($offset,$count,$buf) = @_;
    my $node = $self->lookup_name($file) or return -1;
    $node->is_file || return -1;
    return $node->write($offset,$count,$buf);
}

sub setattr { 0 }

package Lufs::Ram::Node;

use constant DR => 0040000;
use constant FL => 0100000;

sub new {
    my $cls = shift;
    my $self = { fs => shift, data => shift };
    unless (exists$self->{data}{f_ino}) { $self->{data}{f_ino} = $self->{fs}->new_ino }
    unless (exists$self->{data}{nodes}or$self->{data}{f_mode}&FL) { $self->{data}{nodes} = [] }
    unless (exists$self->{data}{f_nlink}) { $self->{data}{f_nlink} = 1 }
    unless (exists$self->{data}{f_uid}) { $self->{data}{f_uid} = 1 }
    unless (exists$self->{data}{f_gid}) { $self->{data}{f_gid} = 1 }
    unless (exists$self->{data}{f_size}) { $self->{data}{f_size} = 512 }
    unless (exists$self->{data}{f_atime}) { $self->{data}{f_atime} = time }
    unless (exists$self->{data}{f_mtime}) { $self->{data}{f_mtime} = time }
    unless (exists$self->{data}{f_ctime}) { $self->{data}{f_ctime} = time }
    unless (exists$self->{data}{f_blksize}) { $self->{data}{f_blksize} = 512 }
    unless (exists$self->{data}{f_blocks}) { $self->{data}{f_blocks} = 1 }
    unless (exists$self->{data}{f_blocks}) { $self->{data}{f_blocks} = 1 }
    bless $self => $cls;
    if ($self->is_file) {
        unless (exists$self->{data}{content}) {
            $self->{data}{content} = '';
        }
    }
    $self;
}

sub is_dir {
    my $self = shift;
    $self->{data}{f_mode} & DR;
}

sub is_file {
    my $self = shift;
    $self->{data}{f_mode} & FL;
}

sub get_attr {
    my $self = shift;
    if ($self->is_file) {
        $self->{data}{f_size} = length($self->{data}{content});
        my $m = $self->{data}{f_size} % $self->{data}{f_blksize};
        $self->{data}{f_blocks} = ($self->{data}{f_size} + ($self->{data}{f_blksize} - $m)) / $self->{data}{f_blksize};
    }
    else {
        $self->{data}{f_blocks} = 1;
        $self->{data}{f_size} = $self->{data}{f_blksize};
    }
    +{map{($_,$self->{data}{$_})}qw{f_ino f_mode f_nlink f_uid f_gid f_size f_atime f_mtime c_ctime f_blksize f_blocks}}
}

sub f_ino {
    my $self = shift;
    $self->{data}{f_ino};
}

sub f_name {
    my $self = shift;
    $self->{data}{f_name};
}

sub fq_name {
    my $self = shift;
    my @p = $self;
    while (my $n = $p[0]->parent) {
        unshift(@p,$n);
    }
    join('/',map{$_->f_name}@p);
}

sub is_empty {
    my $self = shift;
    $self->is_dir?$#{$self->{nodes}}==-1:$self->is_file?$self->f_size==0:0;
}

sub parent {
    my $self = shift;
    $self->{parent};
}

sub lookup_ino {
    my $self = shift;
    my $ino = shift;
    if ($ino == $self->f_ino) {
        return $self;
    }
    unless ($self->is_dir) { return }
    for (@{$self->{nodes}}) {
        if (my $node = $_->lookup_ino($ino)) {
            return $node;
        }
    }
    return;
}

sub del_node {
    my $self = shift;
    my $ino = ref($_[0])?shift->f_ino:shift;
    $self->{nodes} = [grep {$_->f_ino!=$ino} @{$self->{nodes}}]
}

sub add_node {
    my $self = shift;
    my $node = shift;
    push @{$self->{nodes}}, $node;
    $node->{parent} = $self;
}

sub lookup_name {
    my $self = shift;
    my $name = shift;
    for (@{$self->{nodes}}) {
        if ($_->f_name eq $name) {
            return $_;
        }
    }
    return;
}

sub read {
    my $self = shift;
    my ($offset,$count) = @_;
    no warnings;
    $self->{data}{f_atime} = time;
    substr($self->{data}{content},$offset,$count);
}

sub touch {
    my $self = shift;
    $self->{data}{a_time} = $self->{data}{m_time} = time;
}

sub write {
    my $self = shift;
    $self->touch;
    my ($offset,$count,$buf) = @_;
    if (length($self->{data}{content})<$offset) {
        my $p = $offset - $self->{data}{content};
        $self->{data}{content} .= chr(0)x$p;
        $self->{data}{content} .= $buf;
        return $count;
    }
    if (length($self->{data}{content})==$offset) {
        $self->{data}{content} .= $buf;
        return $count;
    }
    if (length($self->{data}{content})>=$offset+$count) {
        substr($self->{data}{content},$offset,$count,$buf);
        return $count;
    }
    if (length($self->{data}{content})>$offset) {
        my $l = length($self->{data}{content})-$offset;
        substr($self->{data}{content},$offset,$l,substr($buf,0,$l));
        $self->{data}{content} .= substr($buf,$l,length($buf)-$l);
        return $count;
    }
}

1;
__END__

=head1 NAME

Lufs::Ram - Storage in a perl data structure

=head1 DESCRIPTION

This is a reference implementation of a ram-based filesystem in perl.

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
