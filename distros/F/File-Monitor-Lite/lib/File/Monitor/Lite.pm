package File::Monitor::Lite;

use 5.8.6;
our $VERSION = '0.652003';
use strict;
use warnings;
use File::Spec::Functions ':ALL';
use File::Find::Rule;
use File::Monitor;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( 
qw(
   monitor 
   watch_list
));
	

sub new {
    my $class = shift;
    my $self = {@_};
    bless $self, $class;
    $self->_init;
    return $self;
}

sub _init{
    my $self = shift;
    -d $self->{in} or die "invalid director\n";
    $self->{in}=rel2abs($self->{in});
    my %w_list = 
        map{$_ => 1}
        File::Find::Rule
            ->file()
            ->name($self->{name})
            ->in($self->{in});
    $self->watch_list(\%w_list);
    $self->monitor(new File::Monitor);
    $self->monitor->watch($_)for keys %w_list;
    $self->monitor->scan;
    $self->{observed}=[keys %w_list];
    $self->{created}=[];
    $self->{deleted}=[];
    $self->{modified}=[];
    1;
}



sub check {
    my $self = shift;
    my $w_list=$self->watch_list;
    my @new_file_list = 
        File::Find::Rule
        ->file()
        ->name($self->{name})
        ->in($self->{in});
    my @new_files = grep { not exists $$w_list{$_} } @new_file_list;
    my @changes = $self->monitor->scan;
    my @deleted_files = 
        map{$_->name}
        grep{$_->deleted} @changes;
    my @modified_files = 
        map{$_->name}
        grep{not $_->deleted} @changes;

    # update waching list
    foreach(@new_files){
        $$w_list{$_}=1;
        $self->monitor->watch($_);
    }
    # unwatch deleted files
    foreach(@deleted_files){
        $self->monitor->unwatch($_);
        delete $$w_list{$_};
    }
    $self->monitor->scan;       
    # do a scan first before next check
    # else next check $self->monitor cannot find differences


    $self->{watch_list}=($w_list);
    $self->{created}= [@new_files];
    $self->{modified}=[@modified_files];
    $self->{observed}=[ keys %$w_list];
    $self->{deleted}= [@deleted_files];
    $self->{anychange}= (
      scalar(@new_files)+
      scalar(@modified_files)+
      scalar(@deleted_files)) ? 1 : 0;

    1;
}
sub created {
    my $self = shift;
    #return () unless @{$self->{created}};
    return sort @{$self->{created}};
}
sub modified {
    my $self = shift;
    return sort @{$self->{modified}};
}
sub observed {
    my $self = shift;
    return sort @{$self->{observed}};
}
sub deleted {
    my $self = shift;
    return sort @{$self->{deleted}};
}
sub anychange{
    my $self = shift;
    return $self->{anychange};
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

File::Monitor::Lite - Monitor file changes

=head1 SYNOPSIS

  use File::Monitor::Lite;
  
  my $monitor = File::Monitor::Lite->new (
      in => '.',
      name => '*.html',
  );

  while ($monitor->check() and sleep 1){
      my @deleted_files = $monitor->deleted;
      my @modified_files = $monitor->modified;
      my @created_files = $monitor->created;
      my @observing_files = $monitor->observed;
      `do blah..` if $monitor->anychange;
  }


=head1 DESCRIPTION

This is another implementaion of File::Monitor. While File::Monitor cannot detect file creation (unless you declare file name first), I use File::Find::Rule to rescan files every time when $monitor->check() is executed. To use this module, just follow synopsis above.

Currently one cannot change file observing rules. To do so, create another monitor object with new rules.

    $m1=File::Monitor::Lite->new(
        name => '*.html',
        in => '.',
    );
    $m1->check();
    #blah...
    $m2=File::Monitor::Lite->new(
        name => '*.css',
        in => '.',
    );
    $m2->check();
    #blah...

=head1 INTERFACE

=over

=item C< new ( args ) >

Create a new C<File::Monitor::Lite> object. 
    
    my $monitor = File::Monitor::Lite->new(
        in => '.',
        name => '*.mp3',
    );

The syntax is inherited from L<File::Find::Rule>. It will applied on L<File::Find::Rule> as

    File::Find::Rule
        ->file()
        ->name('*.mp3')
        ->in('.');

As described in L<File::Find::Rule>, name can be globs or regular expressions.

    name => '*.pm',                     # a simple glob
    name => qr/.+\.pm$/,                # regex
    name => ['*.mp3', qr/.+\.ogg$/],    # array of rules
    name => @rules,

=item C< check() >

Check if any file recognized by File::Find::Rule has changed (created, modified, deleted.) The usage is simple:

    $monitor->check();

=item C< created >

Returns an array of file names which has been created since last check.

=item C< modified >

Returns an array of file names which has been modified since last check.

=item C< deleted >

Returns an array of file names which has been deleted since last check.

=item C< observed >

Returns an array of file names which monitor is observing at.

=back

=head1 SEE ALSO

L<File::Find::Rule>, L<File::Monitor>

=head1 AUTHOR

dryman, E<lt>idryman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by dryman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
