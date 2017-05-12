package Devel::Chitin::Actionable;

use strict;
use warnings;

our $VERSION = '0.10';

use Digest::MD5 qw(md5);
use Carp;

sub new {
    my $class = shift;

    my %params = __required([qw(file line code)], @_);

    my $self = \%params;
    bless $self, $class;
    $self->_insert();
    return $self;
}

sub __required {
    my $required_params = shift;
    my %params = @_;
    do { defined($params{$_}) || Carp::croak("$_ is a required param") }
        foreach @$required_params;
    return %params;
}

sub get {
    my $class = shift;
    return $class if (ref $class);

    my %params = __required([qw(file)], @_);

    our %dbline;
    local(*dbline) = $main::{'_<' . $params{file}};
    return unless %dbline;

    my @candidates;

    my $type = $class->type;
    if (!$params{line}) {
        @candidates =
              map { $_->{$type} ? @{$_->{$type}} : () } # only lines with the type we're looking for
              grep { $_ }      # only lines with something
              values %dbline;  # All action/breakpoint data for this file
    } else {
        my $line = $params{line};
        @candidates = ($dbline{$line} && $dbline{$line}->{$type})
                    ? @{ $dbline{$line}->{$type}}
                    : ();
    }
            
    if ($params{code}) {
        @candidates = grep { $_->{code} eq $params{code} }
                        @candidates;
    }

    if ($params{inactive}) {
        @candidates = grep { $_->{inactive} eq $params{inactive} }
                        @candidates;
    }

    return @candidates;
}

sub _insert {
    my $self = shift;

    # Setting items in the breakpoint hash only gets
    # its magical DB-stopping abilities if you're in
    # pacakge DB.  Otherwise, you can alter the breakpoint
    # data, other users will see them, but the debugger
    # won't stop
    package DB;
    our %dbline;
    local(*dbline) = $main::{'_<' . $self->file};

    my $bp_info = $dbline{$self->line} ||= {};
    my $type = $self->type;
    $bp_info->{$type} ||= [];
    push @{$bp_info->{$type}}, $self;
}

sub delete {
    my $self = shift;

    my($file, $line, $code, $type, $self_ref);
    if (ref $self) {
        ($file, $line, $code) = map { $self->$_ } qw(file line code);
        $type = $self->type;
        $self_ref = $self . '';
    } else {
        my %params = __required([qw(file line code type)], @_);
        ($file, $line, $code, $type) = @params{'file','line','code','type'};
    }

    our %dbline;
    local(*dbline) = $main::{'_<' . $file};
    my $bp_info = $dbline{$line};
    return unless ($bp_info && $bp_info->{$type});

    my $bp_list = $bp_info->{$type};
    for (my $i = 0; $i < @$bp_list; $i++) {
        my($its_file, $its_line, $its_code) = map { $bp_list->[$i]->$_ } qw(file line code);
        if ($file eq $its_file
            and
            $line == $its_line
            and
            $code eq $its_code
            and
            ( defined($self_ref) ? $self_ref eq $bp_list->[$i] : 1 )
        ) {
            splice(@$bp_list, $i, 1);
            last;
        }
    }

    if (! @$bp_list) {
        # last breakpoint/action removed for this line
        delete $bp_info->{$type};
    }

    if (! %$bp_info) {
        # No breakpoints or actions left on this line
        $dbline{$line} = undef;
    }
    return $self;
}

 
sub file    { return shift->{file} }
sub line    { return shift->{line} }
sub once    { return shift->{once} }
sub type    { my $class = shift;  $class = ref($class) || $class; die "$class didn't implement method type" }

sub code    {
    my $self = shift;
    if (@_) {
        $self->{code} = shift;
    }
    return $self->{code};
}

sub inactive {
    my $self = shift;
    if (@_) {
        $self->{inactive} = shift;
    }
    return $self->{inactive};
}

package Devel::Chitin::Breakpoint;

use base 'Devel::Chitin::Actionable';

sub new {
    my($class, %params) = @_;
    $params{code} = 1 unless (exists $params{code});
    $class->SUPER::new(%params);
}

sub type() { 'condition' };

package Devel::Chitin::Action;

use base 'Devel::Chitin::Actionable';

sub type() { 'action' };

1;

__END__

=pod

=head1 NAME

Devel::Chitin::Actionable - Get and set breakpoints and actions

=head1 SYNOPSIS

  my $unconditional_bp = Devel::Chitin::Breakpoint->new(
                            file => $filename, line => 123 );

  my $conditional_bp = Devel::Chitin::Breakpoint->new(
                            file => $filename, $line => 123,
                            code => q($a eq 'stop'));

  my $inactive_bp = Devel::Chitin::Breakpoint->new(
                            file => $filename, $line 123,
                            inactive => 1);

  my @bp = Devel::Chitin::Breakpoint->get(file => $filename, line => 123);
  printf("breakpoint on line %d of %s: %s\n",
            $bp[0]->line, $b[0]->file, $bp[0]->code);

=head1 DESCRIPTION

Used to manipulate breakpoints and actions in the debugged program.
Breakpoints are used to stop execution of the debugged program and let the
debugging system take control there.  Actions are used to run arbitrary
code before a line in the debugged program executes.

=head1 Breakpoints

Breakpoints are associated with a file and line number, and the same
file/line combination may have more than one breakpoint.  At each line
with one or more breakpoints, all those breakpoints are tested by
eval-ing (as a string eval) their C<code> in the context of the debugged
program.  If any of these tests returns true, the debugger will stop the
program before executing that line.

=head2 Constructor

  my $bp = Devel::Chitin::Breakpoint->new(file => $f, line => $l,
                                        [ code => $code ],
                                        [ once => 1 ],
                                        [ inactive => 1]);

Creates a new Breakpoint object.  C<file> and C<line> are required arguments.
C<file> must be a filename as it appears in $main::{"<_$file"}.  If C<code>
is omitted, the value "1" is used as a default which creates an unconditional
breakpoint.  If C<once> is a true value, then the breakpoint will delete
itself after triggering.  If C<inactive> is true, the breakpoint will not
trigger.

=head2 Methods

=over 4

=item my @bp = Devel::Chitin::Breakpoint->get(file => $f, %other_params);

Retrieve breakpoints.  Always returns a list of matching breakpoints.
C<file> is required, and if no other filters are used, returns all the
breakpoints for that file.  You may also filter by line, code and inactive.

=item $bp->file

=item $bp->line

=item $bp->once

Read-only accessors that return whatever values were used to create the
breakpoint.

=item $bp->code

=item $bp->code($string)

Mutator that retrieves the breakpoint's code condition, or sets it.

=item $bp->inactive();

=item $bp->inactive( 1 | 0);

Mutator that retrieves the current inactive flag, or sets it.

=item $bp->delete();

Remove a breakpoint.  Deleted breakpoints will never trigger again.

=back

=head1 Actions

Actions are a lot like breakpoints; they are associated with a file and line
number, and they have code that runs before that line in the program is
executed.  The difference is that the return value from the code is ignored.

The code is evaluated in the context of the running program, so it can, for
example, affect variables there or print them out.

=head2 Constructor

  my $act = Devel::Chitin::Action->new(file => $f, line => $l, code => $code,
                                        [ once => 1],
                                        [ inactive => 1]);

Creates a new Action object.  C<file>, C<line> and C<code> are required
arguments.  C<file> must be a filename as it appears in $main::{"<_$file"}.
breakpoint.  If C<once> is a true value, then the action will delete
itself after running.  If C<inactive> is true, the action will not run.

=head2 Methods

=over 4

=item my @acts = Devel::Chitin::Action->get(file => $f, %other_params);

Retrieve actions.  Always returns a list of matching actions.  C<file> is
required, and if no other filters are used, returns all the actions for
that file.  You may also filter by line, code and inactive.

=item $act->file

=item $act->line

=item $act->once

Read-only accessors that return whatever values were used to create the
action.

=item $act->code

=item $act->code($string);

Mutator that retrieves the action's code, or set it.

=item $act->inactive();

=item $act->inactive( 1 | 0);

Mutator that retrieves the current inactive flag, or sets it.

=item $act->delete();

Remove an action.  Deleted actions will never run again.

=back

=head1 SEE ALSO

L<Devel::Chitin>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2016, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
