package Iterator::File;

## $Id: File.pm,v 1.14 2008/06/18 06:46:27 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use Carp;
use IO::File;
use Data::Dumper;

use Iterator::File::Utility;
use Iterator::File::Status;

require Exporter;

our @ISA = qw(Exporter Iterator::File::Utility);

our @EXPORT = qw(
  iterator_file	
);

our $VERSION = substr(q$Revision: 1.14 $, 10);

use overload '""' => \&overload_as_string,
  '+' => 'overload_add';

my %default_config =
  (
   'chomp'                      => 1,
   'source_class'               => 'Iterator::File::Source::FlatFile',
   'state_class_without_resume' => 'Iterator::File::State::Interface',
   'state_class_with_resume'    => 'Iterator::File::State::TempFile',
   'resume'                     => 0,
   'repeat_on_resume'           => 1,
   'verbose'                    => 0,
   'status'                     => 0,
  );
                      


sub iterator_file {
  my ($filename, %config) = @_;

  croak("No file name given to iterator_file!") unless (defined($filename));
  my $iterator = new Iterator::File( %config,
                                     'filename' => $filename
                                     );
  return $iterator;
}



sub new {
  my ($class, %config) = @_;

  %config = (%default_config, %config);
  ## What type of default state class do we use?
  ## Make sure we respect any explicit input from the user.
  unless (defined $config{'state_class'}) {
    if ($config{'resume'}) {
      $config{'state_class'} = $config{'state_class_with_resume'};
    } else {
      $config{'state_class'} = $config{'state_class_without_resume'};
    }
  }

  my $self = $class->SUPER::new( %config );
  bless(\%config, $class);

  ## Instatiate the needed objects...
  my $source_class = $config{'source_class'};
  my $state_class  = $config{'state_class'};
  
  $self->_lazy_load_module( $source_class );
  $self->_lazy_load_module( $state_class );
  
  $self->{'source_object'} = $source_class->new( %config );
  $self->{'state_object'}  = $state_class->new( %config );

  ## Do we care about status?
  if ($self->{'status'}) {
    $self->{'status_object'} = Iterator::File::Status->new( %config );
  }

  $self->initialize();

  return $self;
}



sub initialize {
  my ($self) = @_;

  $self->{'source_object'}->initialize();
  $self->{'state_object'}->initialize();

  ## Pickup where we left off...
  if ($self->{resume}) {
    $self->{source_object}->advance_to( $self->{'state_object'}->marker() );
  }
}



sub next {
  my ($self) = @_;

  my $state  = $self->{'state_object'};
  my $source = $self->{'source_object'};

  if ( $self->{repeat_on_resume} ) {
    $state->advance_marker();
  }

  my $next_data = $source->next();

  if ( !$self->{repeat_on_resume} ) {
    $state->advance_marker();
  }

  unless ( defined($next_data) ) {
    ## All done
    $self->_verbose( "Finished.  Cleaning up..." );
    $state->finish();
    $source->finish();
  } else {
    if ($self->{'status'}) {
      my $marker = $self->{'state_object'}->marker();
      $self->{'status_object'}->emit_status( $marker );
    }
  }

  return $next_data;
}  



sub skip_next {
  my ($self, $num) = @_;

  $num ||= 1;
  while ($num--) {
    $self->next();
  }

  return $self->value();
}



sub value {
  my ($self) = @_;

  return $self->{'source_object'}->value();
}  



sub finish {
  my ($self) = @_;

  $self->{'source_object'}->finish();
  $self->{'state_object'}->finish();
}  



sub state_object {
  my ($self) = @_;

  return  $self->{'state_object'}; 
}



sub source_object {
  my ($self) = @_;
 
  return  $self->{'source_object'}; 
}



sub emit_status {
  my ($self) = @_;
}



sub _lazy_load_module {
  my ($self, $module, @module_args) = @_;

  $self->_debug( "Loading '$module'... ");
  eval "require $module";
  if ($@) {
    confess ("Unable to load '$module': $@!");
  }

  $module->import( @module_args );
}



sub overload_as_string {
  my ($self) = @_;

  return $self->value();
}



sub overload_add {
  my ($self, $num) = @_;

  $self->skip_next($num);
  
  return $self;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iterator::File -- A file iterator, optionally stateful and verbose.

=head1 SYNOPSIS
 
 use Iterator::File;
 
 ## Simplest form...
 $i = iterator_file( 'mydata.txt' );
 while( $i++ ) {
   &something_interesting( $i );
 }
 
 
 ## Disable auto-chomp, emit status, and allow us to resume if ^C...
 $i = iterator_file( 'mydata.txt',
                     'chomp'  => 0,
                     'status' => 1,
                     'resume' => 1,
                    );
 while( $i++ ) {
   &something_interesting( $i );
 }
 
 
 ## OO style...
 $i = iterator_file( 'mydata.txt' );
 while( $i->next() ) {
   &something_interesting( $i->value() );
 }
 
=head1 DESCRIPTION

C<Iterator_File> is an attempt to take some repetition & tedium out of
processing a flat file.  Whenever doing so, I found myself adapting
prior scripts so that processes could be resumed, emit status, etc.  Hence
an itch (and this module) was born.

=head1 FUNCTIONS

=over 4

=item B<iterator_file($file, %config)>

Returns an C<Iterator::File> object.  See C<%config> section below for additional information on options.

=cut

=head1 METHODS

=over 4

=item B<new(%config)>

The constructor returns a new C<Iterator::File> object, handling
arugment defaults & validation, and automatically invoking C<initialize>.

=cut

=item B<initialize()>

Executes all startup work required before iteration.  E.g., opening
resources, detecting if a prior process terminated early & resuming, etc.

=cut

=item B<next(), '++'>

Increment the iterator & return the new value.

=cut

=item B<value(), string context>

Return the current value, without advancing.

=cut

=item B<advance_to( $location )>

Advance the iterator to $location.  If $location is B<behind> the current
location, behavior is undefined.  (I.e., don't do that.)

=cut

=item B<finish()>

Automatically invoked when the B<complete> list is process.  If the
process dies before the last item of the list, this process is
I<intentionally> not invoked.


=cut

=back

=head1 B<%config> options

=head2 General

=over 4

=item B<chmop>

Automatically chomp each line.  Default: enabled.

=cut

=item B<verbose>

Enable verbose messaging for things such as temporary files.   Default: disabled.

Note: for status messages, see C<Status> below

=cut

=item B<debug>

Enable debugging messages.  It can also be enabled by setting the
environmental variable ITERATOR_FILE_DEBUG to something true (to avoid
modifying code to enable it).  Default: disabled.

=cut

=back

=head2 Resume

=over 4

=item B<resume>

If enabled,  C<Iterator::File> will keep track of which lines you've seen,
even between invokations.  That way if you program unexpectedly dies (e.g.,
via a bug or ^C), you can pick up where you left off just by running your
program again.  Default: disabled.

=cut

=item B<repeat_on_resume>

If enabled, C<Iterator::File> will error on the side of giving you the
same line twice between invocations.  E.g., if your program were to
be restarted after dieing on the 100th line, C<repeat_on_resume> would
give you the 100th line on the 2nd invocation (verus the 101th).  Default: disabled.

=cut

=item B<update_frequency>

How often to update state.  For very large data sets with light individual
processing requirements, it may be worth setting to something other than 1.
Default: 1.

=cut

=item B<state_class>

Options: C<Iterator::File::State::TempFile> and
C<Iterator::File::State::IPCShareable>.  TempFile is the default and in
a lot of cases should be good enough.  If you have philosophical objections
to a frequently changing value living on disk (or a really, really slow
disk), you can used shared memory via IPC::Sharable.

=cut

=back

=head2 Status

=over 4

=item B<status_method>

What algorithm to use to display status.  Options are C<emit_status_logarithmic>,
C<emit_status_fixed_line_interval>, and C<emit_status_fixed_time_interval>.

C<emit_status_fixed_time_interval> will display status logarithmically.  I.e.,
1, 2, 3 ... 9, 10, 20, 30 ... 90, 100, 200, 300 ... 900, 1000, 2000, etc.

C<emit_status_fixed_line_interval> display status every X lines, where X is
defined by C<status_line_interval>.

C<emit_status_fixed_time_interval> display status every X lines, where X is
defined by C<status_time_interval>.

Default: emit_status_logarithmic.

=cut

=item B<status_line_interval>

If C<status_method> is C<emit_status_fixed_line_interval>, controls how
frequently to display status.  Default: 10 (lines).

=cut

=item B<status_time_interval>

If C<status_method> is C<emit_status_time_line_interval>, controls how
frequently to display status.  Default: 2 (seconds).

=cut

=item B<status_filehandle>

Filehandle to use for printing status.  Default: STDERR.

=cut

=item B<status_line>

Format of status line.  Default: "Processing row '%d'...\n".

=cut

=back

=head1 BUGS & CAVEATS

B<Do not call chop or chomp on the iterator!!>  Unfortuntely, doing so
destorys your object & leaves you with a plain ol' string. :( 

=head1 SEE ALSO

Iterator::File

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
