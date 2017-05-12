# calculate and stores ngrams of various types

package IDS::Algorithm::Ngram;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Ngram::VERSION = "1.0";

# BUG BUG BUG
# Need to be able to handle either token list or strings.
# choose which by a parameter

use strict;
use warnings;
use IO::Handle;
use Carp qw(cluck carp confess);

sub param_options {
    my $self = shift;

    return (
	    "ngram_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "ids_state=s"     => \${$self->{"params"}}{"state_file"},
	    "length=i"        => \${$self->{"params"}}{"length"},
	   );
}

sub default_parameters {
    my $self = shift;
    $self->{"params"} = {
                         "verbose" => 0,
                         "length" => 3,
			 "state_file" => 0,
			};
}

sub length {
    my $self = shift;
    return ${$self->{"params"}}{"length"};
}

sub ngrams {
    my $self = shift;
    my $data = shift or
	confess *add_instance{PACKAGE} . "::add_instance missing data to add";
    my $length = ${$self->{"params"}}{"length"};
    my @ngrams = ();

    my $ngram = "";
    my @tokens = @{$data};
    while (@tokens >= $length) {
	$ngram = join "; ", @tokens[0..($length-1)];
	push @ngrams, $ngram;
	shift @tokens;
    }
    return @ngrams;
}

sub add {
    my $self = shift;
    my $data = shift or
	confess *add_instance{PACKAGE} . "::add_instance missing data to add";
    my $length = ${$self->{"params"}}{"length"};

    for my $ngram ($self->ngrams($data)) {
	${$self->{"ngrams"}}{$ngram}++;
    }
}

sub test {
    my $self = shift;
    my $data = shift or # ref to a list of the data to test
        confess *test_instance{PACKAGE} . "::test_instance missing tokenref";
    my ($ngram, @ngrams, $misfires, $count);
    my $verbose = ${$self->{"params"}}{"verbose"};

    $misfires = 0;
    @ngrams = $self->ngrams($data);
    $count = scalar(@ngrams);
    for $ngram (@ngrams) {
	if ($verbose > 1) {
	    print ${$self->{"ngrams"}}{$ngram} ? "Yes" : "No";
	    print ": '$ngram'\n";
	}
        ${$self->{"ngrams"}}{$ngram} or $misfires++;
    }
    ### assume if we got no n-grams that it is not similar at all
    return $count == 0 ? 0 : ($count - $misfires) / $count;
}

sub save {
    my $self = shift;
    my $fname = shift or confess *save{PACKAGE} .  "::save missing filename";
    my $fh = new IO::File ">$fname" or warn "Unable to open $fname: $!\n";
    my $length = ${$self->{"params"}}{"length"};

    my ($ngram, $count);

    print $fh "$length\n";
    while (($ngram, $count) = each %{$self->{"ngrams"}}) {
	print $fh "$count $ngram\n";
    }
}

sub load {
    my $self = shift;
    my $fname = shift;
    defined($fname) && $fname or
        $fname = ${$self->{"params"}}{"state_file"};
    defined($fname) && $fname or
	confess *load{PACKAGE} .  "::load missing filename";

    my ($ngram, $count, $n, $fh);

    $fh = new IO::File "<$fname" or
        confess *load{PACKAGE} . "::load Unable to open $fname for reading: $!";

    ${$self->{"params"}}{"length"} = <$fh>;
    chomp(${$self->{"params"}}{"length"});
    ${$self->{"params"}}{"length"} or
     confess *load{PACKAGE} .  "::load from $fname missing length";

    $n = 0;
    %{$self->{"ngrams"}} = ();
    while (<$fh>) {
	chomp;
	$n++;
	($count, $ngram) = split /\s+/, $_, 2;
	print "load count $count gram $ngram\n" if ${$self->{"params"}}{"verbose"} > 2;
	${$self->{"ngrams"}}{$ngram} = $count;
    }
    print "Loaded $n " . ${$self->{"params"}}{"length"} . "-grams\n" if
        ${$self->{"params"}}{"verbose"};
    my @foo = %{$self->{"ngrams"}};
    my $foo = scalar(@foo) / 2;
    print "DB has $foo entries\n";
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

=cut

1;
