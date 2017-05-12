package Integrator::Test::TAP::Model::Patch;
use base 'Test::TAP::Model';
		
use warnings;
use strict;

use vars qw($VERSION);

=head1 NAME

Integrator::Test::TAP::Model::Patch - modified version of Test::TAP::Model

=head1 VERSION

Version 0.01

=cut

$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

=head1 SYNOPSIS

Very simple wrapper to get the full text output in the diags fields...
This is essentially the analyze_file function from Test::Harness::Straps by
Michael G Schwern C<< <schwern@pobox.com> >>, currently maintained by
Andy Lester C<< <andy@petdance.com> >>.

All other functions included here are exported simply to avoid breaking 
the code.

Our intent is to have the modification included in the original code
of Test::TAP::Model (maybe with a switch to enable the code...). We use
Integrator::Test::TAP::Model in the meantime.

=head1 EXPORT

=head1 FUNCTIONS

=head2 analyze_file

This function has been modified to have all test output merged back into
STDOUT. Then this merged output is printed both to STDOUT and STDERR.

Otherwise, this function does the same thing as Test::TAP::Model::analyze_file.

=cut

sub analyze_file {
    my($self, $file) = @_;

    unless( -e $file ) {
        $self->{error} = "$file does not exist";
        return;
    }

    unless( -r $file ) {
        $self->{error} = "$file is not readable";
        return;
    }

    local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;
    if ( $Test::Harness::Debug ) {
        local $^W=0; # ignore undef warnings
        print "# PERL5LIB=$ENV{PERL5LIB}\n";
    }

    # *sigh* this breaks under taint, but open -| is unportable.
    my $line = $self->_command_line($file);

    ############unless ( open(FILE, "$line|" )) {
    unless ( open(FILE, "$line 2>&1| perl -pe 'print STDERR'|" )) {
        print "can't run $file. $!\n";
        return;
    }

    my $results = $self->analyze_fh($file, \*FILE);
    my $exit    = close FILE;

    $results->set_wait($?);
    if ( $? && $self->{_is_vms} ) {
        eval q{use vmsish "status"; $results->set_exit($?); };
    }
    else {
        $results->set_exit( _wait2exit($?) );
    }
    $results->set_passing(0) unless $? == 0;

    $self->_restore_PERL5LIB();

    return $results;
}

eval { require POSIX; &POSIX::WEXITSTATUS(0) };
if( $@ ) {
    *_wait2exit = sub { $_[0] >> 8 };
}
else {
    *_wait2exit = sub { POSIX::WEXITSTATUS($_[0]) }
}

=head2 run_tests

This function has been modified to print the file name before
launching the tests. Otherwise this function does the same thing as
Test::TAP::Model::run_tests.

=cut

sub run_tests {
	my $self = shift;

	$self->_init;

	$self->{meat}{start_time} = time;

	foreach my $file (@_) {
		print "$file\n";
		$self->run_test($file);
	}

	$self->{meat}{end_time} = time;
}

=head1 AUTHOR

This module is very heavily based on Test::TAP:Model from Michael G
Schwern C<< <schwern@pobox.com> >>, and currently maintained by Andy
Lester C<< <andy@petdance.com> >>.

It has been modified by Francois Perron, C<< <integrator-tech-support at cydone.com> >>

=head1 BUGS

Please report any bugs or feature requests to the author through the provided email.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ./lib/Integrator/Test/TAP/Model/Patch.pm 

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Of course, Test::TAP::Model is Copyrighted to Michael G Schwern C<<
<schwern@pobox.com> >>, and currently maintained by Andy Lester C<<
<andy@petdance.com> >>.

this mod is Copyright 2006 Francois Perron, Cydone Solutions, this module
is released under the same terms as perl.

=cut

1;
