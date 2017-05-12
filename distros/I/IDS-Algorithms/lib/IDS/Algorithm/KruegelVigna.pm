package IDS::Algorithm::KruegelVigna;
use base qw(IDS::Algorithm);
$IDS::Algorithm::KruegelVigna::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::KruegelVigna - an IDS algorithm based on the Kruegel and
Vigna paper (L</SEE ALSO>).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

See IDS::Algorithm.pm docs for any functions not described here.

This algorithm is HTTP-specific and will not work with any other data
source.

This algorithm requires two passes over the training data to function
properly.

=cut

use strict;
use warnings;
use IDS::Algorithm::Length;
use IDS::Algorithm::KVCharDist;
use IDS::Algorithm::Order;
use IDS::Algorithm::Presence;
use IDS::Algorithm::EnumOrRandom;
use IDS::Algorithm::MM;
use Carp qw(cluck carp confess);

=over

=item new()

=item new(params)

=item new(filehandle, params)

Create the object for the algorithm.  If the parameters are supplied,
they are used; otherwise everything is defaults (unsurprisingly).  
If a filehandle is supplied, the filehandle is taken as the source for
a load operation.

=back

=cut

# Part of the logic here seems kind of backwards, but we cannot load
# until parameters have been loaded.  Some of the parameters may affect
# how we load.
sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { };
    my $source;
    my $state = 0;

    # necessary before we call handle_parameters.
    bless($self, $class);

    $self->default_parameters;
    $source = $self->handle_parameters(@_);

    $self->load($source) if defined($source); # unlikely to occur
					      # due to IDS::Test framework

    $self->{"length"} = new IDS::Algorithm::Length;             # 4.1
    $self->{"chardist"} = new IDS::Algorithm::KVCharDist;       # 4.2
    $self->{"markov"} = new IDS::Algorithm::MM;                # 4.3
    $self->{"enumorrandom"} = new IDS::Algorithm::EnumOrRandom; # 4.4
    $self->{"presence"} = new IDS::Algorithm::Presence;         # 4.5
    $self->{"order"} = new IDS::Algorithm::Order;               # 4.6

    # weights are per algorithm.  We store the minimum similarity, since 
    # the test framework has everything in [0,1] with 0 being anomalous
    $self->{"worst"} = {};
    ${$self->{"worst"}}{"length"} = 1.0;
    ${$self->{"worst"}}{"chardist"} = 1.0;
    ${$self->{"worst"}}{"markov"} = 1.0;
    ${$self->{"worst"}}{"enumorrandom"} = 1.0;
    ${$self->{"worst"}}{"presence"} = 1.0;
    ${$self->{"worst"}}{"order"} = 1.0;

    return $self;
}

sub param_options {
    my $self = shift;

    # Local parameters last, to override the state file from the
    # sub-objects
    return (
	    $self->{"length"}->param_options,
	    $self->{"chardist"}->param_options,
	    $self->{"markov"}->param_options,
	    $self->{"enumorrandom"}->param_options,
	    $self->{"presence"}->param_options,
	    $self->{"order"}->param_options,
	    "kv_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "ids_state=s"  => \${$self->{"params"}}{"state_file"},
	    "kvfudge=f"    => \${$self->{"params"}}{"fudge"},
	    "MMmap_chars"  => \${$self->{"params"}}{"map_chars"},
	   );
}

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose"    => 0,
        "state_file" => 0,
	"fudge"      => 0.10,
	"map_chars"  => 0,
    );
}

sub parameters {
    my $self = shift;
    my @params = ( %{$self->{"params"}} );

    push @params, $self->{"length"}->parameters if defined($self->{"length"});
    push @params, $self->{"chardist"}->parameters if defined($self->{"chardist"});
    push @params, $self->{"markov"}->parameters if defined($self->{"markov"});
    push @params, $self->{"enumorrandom"}->parameters if defined($self->{"enumorrandom"});
    push @params, $self->{"presence"}->parameters if defined($self->{"presence"});
    push @params, $self->{"order"}->parameters if defined($self->{"order"});

    if ($#_ == -1) {
	return wantarray ? @params : \@params;
    }

    # If we are setting, set in all of the sub-objects
    # For value, return the last
    if ($#_ == 1) {
        my $old = ${$self->{"params"}}{$_[0]};
	${$self->{"params"}}{$_[0]} = $_[1];
	$old = $self->{"length"}->parameters($_[0], $_[1]);
	$old = $self->{"chardist"}->parameters($_[0], $_[1]);
	$old = $self->{"markov"}->parameters($_[0], $_[1]);
	$old = $self->{"enumorrandom"}->parameters($_[0], $_[1]);
	$old = $self->{"presence"}->parameters($_[0], $_[1]);
	$old = $self->{"order"}->parameters($_[0], $_[1]);
        return $old;
    }

    scalar(@_) % 2 != 0 and confess "odd > 1 number of parameters passed to ",
	*parameters{PACKAGE}, ".  See documentation for proper usage.\n";

    # If we are setting, set in all of the sub-objects
    for (my $i = 0; $i < $#_; $i+=2) {
	${$self->{"params"}}{$_[$i]} = $_[$i+1];
	$self->{"length"}->parameters($_[$i], $_[$i+1]);
	$self->{"chardist"}->parameters($_[$i], $_[$i+1]);
	$self->{"markov"}->parameters($_[$i], $_[$i+1]);
	$self->{"enumorrandom"}->parameters($_[$i], $_[$i+1]);
	$self->{"presence"}->parameters($_[$i], $_[$i+1]);
	$self->{"order"}->parameters($_[$i], $_[$i+1]);
    }

    return 1;
}


# Instead of file to save in, our argument will be a dir to save in.
sub save {
    my $self = shift;
    my $dir = $self->find_fname(shift);
    defined($dir) && $dir or
        confess *save{PACKAGE} .  "::save missing dir";

    unless (-d $dir) {
        warn "$dir does not exist; creating.\n";
	mkdir $dir or confess "mkdir '$dir' failed: $!\n";
    }
    $dir =~ m!/$! or $dir .= "/";
   
    $self->{"length"}->save($dir . "length");
    $self->{"chardist"}->save($dir . "chardist");
    $self->{"markov"}->save($dir . "markov");
    $self->{"enumorrandom"}->save($dir . "enumorrandom");
    $self->{"presence"}->save($dir . "presence");
    $self->{"order"}->save($dir . "order");

    $self->calc_weights unless defined($self->{"weight"});
    my $wfname = $dir . "weights";
    open(WF, ">$wfname") or confess "Cannot open $wfname for writing: $!\n";
    for my $m (keys %{$self->{"weight"}}) {
        print WF "$m: ", ${$self->{"weight"}}{$m}, "\n";
    }
    close WF;
    my $bfname = $dir . "bottoms";
    open(WF, ">$bfname") or confess "Cannot open $bfname for writing: $!\n";
    for my $m (keys %{$self->{"bottom"}}) {
        print WF "$m: ", ${$self->{"bottom"}}{$m}, "\n";
    }
    close WF;
}

# Instead of file to load from, our argument will be a dir to load from.
sub load {
    my $self = shift;
    my $dir = $self->find_fname(shift);
    defined($dir) && $dir or
        confess *load{PACKAGE} .  "::load missing dir";

    $dir =~ m!/$! or $dir .= "/";

    $self->{"length"}->load($dir . "length");
    $self->{"chardist"}->load($dir . "chardist");
    $self->{"markov"}->load($dir . "markov");
    $self->{"enumorrandom"}->load($dir . "enumorrandom");
    $self->{"presence"}->load($dir . "presence");
    $self->{"order"}->load($dir . "order");

    my $wfname = $dir . "weights";
    open(WF, "$wfname") or confess "Cannot open $wfname for reading: $!\n";
    while (<WF>) {
        chomp;
	my ($m, $w) = split(/: /, $_, 2);
        ${$self->{"weight"}}{$m} = $w;
    }
    close WF;

    my $bfname = $dir . "bottoms";
    open(WF, "$bfname") or confess "Cannot open $bfname for reading: $!\n";
    while (<WF>) {
        chomp;
	my ($m, $w) = split(/: /, $_, 2);
        ${$self->{"bottom"}}{$m} = $w;
    }
    close WF;
}

sub method {
    my $self = shift;
    my $string = shift or
        confess "bug: missing string to ", *method{PACKAGE} . "::method";
    
    # The method is the first "word" in the string.
    $string =~ /([^\s]+)\s/;
    return $1;
}

sub path {
    my $self = shift;
    my $string = shift or
        confess "bug: missing string to ", *method{PACKAGE} . "::method";
    
    # The path is the second "word" in the string.  Assume greedy
    # pattern matching
    $string =~ /[^\s]+\s+([^\s]+)/;
    return $1;
}

sub test {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift or
        confess "bug: missing string to ", *test{PACKAGE} . "::test";
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";
    my $verbose = ${$self->{"params"}}{"verbose"};

    # This test is only applied to GET URIs
    # All others are considered normal
    return 1 unless $self->method($string) eq "GET";

    my $uri = $self->path($string);
    my $q = $self->extract_query($uri);
    my $path = $self->extract_qpath($uri);

    # This test is only applied to CGI queries
    # All others are considered normal
    return 1 unless $q;

    if (defined($q)) {
	my @Sq = split(/\&/, $q);
	my @Sa = @Sq;
	my @Sv = @Sq;
	
	map { s/=.*// } @Sa;
	map { s/.*=// } @Sv;

	# For Markov model; KV mapped characters to a class of their case
	my $mm_q = $q;
	if (${$self->{"params"}}{"map_chars"}) {
	    $mm_q =~ tr/a-z/xxxxxxxxxxxxxxxxxxxxxxxxxx/;
	    $mm_q =~ tr/A-Z/XXXXXXXXXXXXXXXXXXXXXXXXXX/;
	}
	my @Sc = split(//, $mm_q);

	my ($n, $m, $r, $l, $c, $mk, $er, $pr, $o, $result);

	defined($self->{"weight"}) or
	    $self->calc_weights;

	$n = 0;

        # attribute lengths (4.1 in kruegel2003anomaly)
	$m = 0;
	$r = 0;
	map {
	        $l = $self->{"length"}->test(undef, $_, $instance);
		$m++;
		$r += $l > ${$self->{"bottom"}}{"length"} ? 1 : 0;
	    } @Sv;
	$result = $r / $m;
	print "Attr len: $result n $n\n" if $verbose;

        # character distribution (4.2 in kruegel2003anomaly)
	$m = 0;
	$r = 0;
	map {
	        $c = $self->{"chardist"}->test(undef, $_, $instance);
		$m++;
		$r += $c > ${$self->{"bottom"}}{"chardist"} ? 1 : 0;
	    } @Sv;
	$result += $r / $m;
	print "chardist: $result n $n\n" if $verbose;

        # Markov model (4.3 in kruegel2003anomaly)
	$mk = $self->{"markov"}->test(\@Sc, undef, $instance);
	$mk = $mk > 0 ? 1 : 0; # from sec 4.3.2 in K&V
	$n++;
	$result += $mk > ${$self->{"bottom"}}{"markov"} ? 1 : 0;
	print "MM: $result n $n\n" if $verbose;

        # enumeration or random values (4.4 in kruegel2003anomaly)
	$er = $self->{"enumorrandom"}->test(\@Sv, undef, $instance);
	$n++;
	$result += $er > ${$self->{"bottom"}}{"enumorrandom"} ? 1 : 0;
	print "enumorrandom: $result n $n\n" if $verbose;

        # attribute presence or absence (4.5 in kruegel2003anomaly)
	# Note non-standard IDS::Algorithm interface
	$pr = $self->{"presence"}->test($path, \@Sa, $instance);
	$n++;
	$result += $pr > ${$self->{"bottom"}}{"presence"} ? 1 : 0;
	print "presence: $result n $n\n" if $verbose;

        # attribute order (4.6 in kruegel2003anomaly)
	$o = $self->{"order"}->test(\@Sv, undef, $instance);
	$n++;
	$result += $o > ${$self->{"bottom"}}{"order"} ? 1 : 0;
	print "attrorder: $result n $n\n" if $verbose;

	print "return = ", $result / $n, "\n\n" if $verbose;

	return $result / $n;
    } else {
	# non-CGI with parameters are considered normal.
        return 1;
    }
}

sub calc_weights {
    my $self = shift;
    my $fudge = 1.0 - ${$self->{"params"}}{"fudge"};

    my @models = qw(length chardist markov enumorrandom presence order);

    for my $m (@models) {
	${$self->{"bottom"}}{$m} = ${$self->{"worst"}}{$m} * $fudge;
	${$self->{"weight"}}{$m} = 1.0 / (1.0 - ${$self->{"bottom"}}{$m});
    }
}

sub add {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift or
        confess "bug: missing string to ", *test{PACKAGE} . "::test";
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    my $verbose = ${$self->{"params"}}{"verbose"};

    # This algorithm only applies to GET URIs
    # All others are considered normal
    my $method = $self->method($string);
    return 1 unless defined($method) && $method eq "GET";

    my $uri = $self->path($string);
    my $q = $self->extract_query($uri);
    my $path = $self->extract_qpath($uri);

    return 1 unless $q;

    print "Query: '$q'\n" if $verbose;

    if (defined($q)) {
	my @Sq = split(/\&/, $q);
	my @Sa = @Sq;
	my @Sv = @Sq;
	
	map { s/=.*// } @Sa;
	map { s/.*=// } @Sv;

	print "Sa @Sa\n" if $verbose;
	print "Sv @Sv\n" if $verbose;

	# For Markov model; KV mapped characters to a class of their case
	my $mm_q = $q;
	if (${$self->{"params"}}{"map_chars"}) {
	    $mm_q =~ tr/a-z/xxxxxxxxxxxxxxxxxxxxxxxxxx/;
	    $mm_q =~ tr/A-Z/XXXXXXXXXXXXXXXXXXXXXXXXXX/;
	}
	my @Sc = split(//, $mm_q);

        # attribute lengths (4.1 in kruegel2003anomaly)
	map { $self->{"length"}->add(undef, $_, $instance) } @Sv;

        # character distribution (4.2 in kruegel2003anomaly)
	map { $self->{"chardist"}->add(undef, $_, $instance) } @Sv;

        # Markov model (4.3 in kruegel2003anomaly)
	$self->{"markov"}->add(\@Sc, undef, $instance);

        # enumeration or random values (4.4 in kruegel2003anomaly)
	$self->{"enumorrandom"}->add(\@Sq, undef, $instance);

        # attribute presence or absence (4.5 in kruegel2003anomaly)
	# Note non-standard IDS::Algorithm interface
	$self->{"presence"}->add($path, \@Sa, $instance);

        # attribute order (4.6 in kruegel2003anomaly)
	$self->{"order"}->add(\@Sv, undef, $instance);
    }
}

sub next_pass {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift or
        confess "bug: missing string to ", *test{PACKAGE} . "::test";
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    # This algorithm only applies to GET URIs
    # All others are considered normal
    return 1 unless $self->method($string) eq "GET";

    my $uri = $self->path($string);
    my $q = $self->extract_query($uri);
    my $path = $self->extract_qpath($uri);

    if (defined($q)) {
	my @Sq = split(/\&/, $q);
	my @Sa = @Sq;
	my @Sv = @Sq;
	
	map { s/=.*// } @Sa;
	map { s/.*=// } @Sv;

	my ($l, $c, $mk, $er, $pr, $o);

        # attribute lengths (4.1 in kruegel2003anomaly)
	map {
	        $l = $self->{"length"}->test(undef, $_, $instance);
		${$self->{"weight"}}{"length"} = $l
		    if $l < ${$self->{"weight"}}{"length"};
	    } @Sv;

        # character distribution (4.2 in kruegel2003anomaly)
	map {
	        $c = $self->{"chardist"}->test(undef, $_, $instance);
		${$self->{"weight"}}{"chardist"} = $c
		    if $c < ${$self->{"weight"}}{"chardist"};
	    } @Sv;

        # Markov model (4.3 in kruegel2003anomaly)
	### Do the Markov models work with characters?
	$mk = $self->{"markov"}->test(\@Sv, undef, $instance);
	$mk = $mk > 0 ? 1 : 0; # from sec 4.3.2 in K&V
	${$self->{"weight"}}{"markov"} = $mk
	    if $mk < ${$self->{"weight"}}{"markov"};

        # enumeration or random values (4.4 in kruegel2003anomaly)
	$er = $self->{"enumorrandom"}->test(\@Sv, undef, $instance);
	${$self->{"weight"}}{"enumorrandom"} = $er
	    if $er < ${$self->{"weight"}}{"enumorrandom"};

        # attribute presence or absence (4.5 in kruegel2003anomaly)
	# Note non-standard IDS::Algorithm interface
	$pr = $self->{"presence"}->test($path, \@Sv, $instance);
	${$self->{"weight"}}{"presence"} = $pr
	    if $pr < ${$self->{"weight"}}{"presence"};

        # attribute order (4.6 in kruegel2003anomaly)
	$o = $self->{"order"}->test(\@Sv, undef, $instance);
	${$self->{"weight"}}{"order"} = $o
	    if $o < ${$self->{"weight"}}{"order"};
    }
}

sub extract_query {
    my $self = shift;
    my $uri = shift or
	confess "bug: missing uri to ", *extract_query{PACKAGE} . "::extract_query";

    if ($uri =~ /\?/) {
        $uri =~ s/^.*\?//;

	return $uri;
    } else {
        return undef; # no query
    }
}

sub extract_qpath {
    my $self = shift;
    my $uri = shift or
	confess "bug: missing uri to ", *extract_qpath{PACKAGE} . "::extract_qpath";

    if ($uri =~ /\?/) {
        $uri =~ s/\?.*$//;

	return $uri;
    } else {
        return undef; # no query
    }
}

sub generalize {
    my $self = shift;
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When
sending bug reports, please provide the versions of IDS::Test.pm,
IDS::Algorithm.pm, IDS::DataSource.pm, the version of Perl, and the
name and version of the operating system you are using.  Since Kenneth
is a PhD student, the speed of the response depends on how the research
is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

"Anomaly detection of web-based attacks" by Christopher Kruegel and
Giovanni Vigna, pages 251--261 in Proceedings of the 10th ACM conference
on computer and communications security, ACM Press, 2003, ISBN 1-58113-738-9.
http://doi.acm.org/10.1145/948109.948144

libAnomaly, by Darren Mutz, Wil Robertson, Fredrik Valeur,
Christopher Kruegel, Giovanni Vigna, and Richard Kemmerer.
http://www.cs.ucsb.edu/~rsg/libAnomaly/index.html

=cut

1;
