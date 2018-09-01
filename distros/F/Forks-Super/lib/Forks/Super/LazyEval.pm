#
# Forks::Super::LazyEval - bg_eval, bg_qx implementations
#

package Forks::Super::LazyEval;
use Forks::Super::Config qw(:all);
use Exporter;
use Carp; 
use strict; 
use warnings;

our @ISA = qw(Exporter);
our @EXPORT = qw(bg_eval bg_qx BG_EVAL BG_QX);
our $VERSION = '0.95';

use constant BG_EVAL => 'Forks::Super::bg_eval';
use constant BG_QX   => 'Forks::Super::bg_qx';

sub _choose_protocol {
    my %options = @_;
    my $preference = $options{protocol} || $ENV{FORKS_SUPER_LAZYEVAL_PROTO};
    if ($preference) {
        if ($preference eq 'YAML' || $preference eq 'Data::Dumper') {
            if (CONFIG_module($preference)) {
                return $preference;
            } elsif ($options{protocol}) {
                carp "bg_eval: bad protocol '$preference' supplied";
            } else {
                carp "bg_eval: bad protocol '$preference' in "
                    . "\$ENV{FORKS_SUPER_LAZYEVAL_PROTO}";
            }
        } elsif ($options{protocol}) {
            carp "bg_eval: bad protocol '$preference' supplied";
        } else {
            carp "bg_eval: bad protocol '$preference' in "
                . "\$ENV{FORKS_SUPER_LAZYEVAL_PROTO}";
        }
    }

    if (CONFIG_module('YAML')) {
	return 'YAML';
    }
    if (CONFIG_module('Data::Dumper')) {
	return 'Data::Dumper';
    }
    return;
}

sub _options {
    my (@options) = @_;
    my %options = ();
    if (@options > 0) {
	if (ref($options[0]) eq 'HASH') {
	    %options = %{$options[0]};
	} else {
	    %options = @options;
	}
    }
    return %options;
}

sub bg_eval (&;@) {
    my ($code, @other_options) = @_;
    my %other_options = _options(@other_options);
    my $proto = _choose_protocol(%other_options);
    if (!defined $proto) {
	croak "Forks::Super: bg_eval call requires " . 
              "either YAML or Data::Dumper\n";
    }

    if (defined($other_options{daemon}) && $other_options{daemon}) {
	croak 'Forks::Super::bg_eval: ',
	    'daemon option not allowed on bg_eval call';
    }
    my $p = $$;
    my $result;

    if ($other_options{wantarray}) {
	require Forks::Super::LazyEval::BackgroundArray;
	$result = Forks::Super::LazyEval::BackgroundArray->new(
	    'eval', $code, 
	    protocol => $proto,
	    %other_options);
    } else {
	require Forks::Super::LazyEval::BackgroundScalar;
	$result = Forks::Super::LazyEval::BackgroundScalar->new(
	    'eval', $code, 
	    protocol => $proto,
	    %other_options);
	if ($$ != $p) {
	    # a WTF observed on Windows
	    croak 'Forks::Super::bg_eval: ',
	        "Inconsistency in process IDs: $p changed to $$!\n";
	}
    }
    return $result;
}

sub bg_qx {
    my ($command, @other_options) = @_;
    my %other_options = _options(@other_options);
    if (defined($other_options{daemon}) && $other_options{daemon}) {
	croak 'Forks::Super::bg_qx: daemon option not allowed on bg_qx call';
    }

    my $p = $$;
    my (@result, $result);

    require Forks::Super::LazyEval::BackgroundScalar;
    $result =  Forks::Super::LazyEval::BackgroundScalar->new(
	'qx', $command, %other_options);
    if ($$ != $p) {
	# a WTF observed on Windows
	croak 'Forks::Super::bg_qx: ',
	"Inconsistency in process IDs: $p changed to $$!\n";
    }
    return $result;
}

# tied class definitions for
# tie $result, 'Forks::Super::bg_XXX', ...  
# tie @result, 'Forks::Super::bg_XXX', ...  
# tie %result, 'Forks::Super::bg_XXX', ...  statements
{
    package Forks::Super::bg_eval;
    sub TIESCALAR {
	my ($pkg,$code,@other_options) = @_;
	my $result = &Forks::Super::LazyEval::bg_eval($code,
						      @other_options);
	my $self = { result => $result };
	bless $self, $pkg;
    }
    sub TIEARRAY {
	my ($pkg,$code,@other_options) = @_;
	my %options = Forks::Super::LazyEval::_options(@other_options);
	$options{wantarray} = 1;
	my $result = &Forks::Super::LazyEval::bg_eval($code, %options);
	my $self = { result => $result, is_array => 1 };
	bless $self, $pkg;
    }
    sub TIEHASH {
	my ($pkg,$code,@other_options) = @_;
	my %options = Forks::Super::LazyEval::_options(@other_options);
	$options{wantarray} = 2;
	my $result = &Forks::Super::LazyEval::bg_eval($code, %options);
	my $self = { result => $result, is_hash => 1 };
	bless $self, $pkg;
    }
    sub FETCH {
	my $this = shift;
	if ($this->{is_array}) {
	    my $index = shift;
	    return $this->array->[$index];
	} elsif ($this->{hash}) {
	    my $key = shift;
	    return $this->hash->{$key};
	} elsif (exists $this->{value}) {
	    return $this->{value};
	} else {
	    return $this->{value} = $this->{result}->_fetch;
	}
    }
    sub STORE {
	my $this = shift;
	if ($this->{is_array}) {
	    my ($index,$value) = @_;
	    my $old = $this->array->[$index];
	    $this->{array}[$index] = $value;
	    return $old;
	} elsif ($this->{is_hash}) {
	    my ($key,$value) = @_;
	    my $old = $this->hash->{$key};
	    $this->{hash}{$key} = $value;
	    return $old;
	} else {
	    my $value = shift;
	    my $old = $this->FETCH;
	    $this->{value} = $value;
	    return $old;
	}
    }
    sub FETCHSIZE {
	my $this = shift;
	return scalar @{$this->array};
    }
    sub STORESIZE {
	my ($this,$count) = @_;
	my $array = $this->array;
	if (@$array < $count) {
	    push @$array, (undef) x ($count-@$array);
#	    push @$array, (undef) x (@$array-$count);
	} else {
	    pop @$array while @$array > $count;
	}
    }
    sub EXTEND {
	my ($this,$count) = @_;
	$this->STORESIZE($count);
    }
    sub EXISTS {
	my ($this,$index) = @_;
	if ($this->{is_array}) {
	    return defined $this->array->[$index];
	} elsif ($this->{is_hash}) {
	    return exists $this->hash->{$index};
	}
    }
    sub FIRSTKEY {
	my $this = shift;
	my $hash = $this->hash;
	() = keys %$hash;
	each %$hash;
    }
    sub SCALAR {
	my $this = shift;
	if ($this->{is_array}) {
	    return $this->FETCHSIZE;
	} elsif ($this->{is_hash}) {
	    my $hash = $this->hash;
	    return scalar %$hash;
	}
    }
    sub NEXTKEY {
	my ($this, $last) = @_;
	my $hash = $this->hash;
	each %$hash;
    }
    sub DELETE {
	my $this = shift;
	if ($this->{is_array}) {
	    my $index = shift;
	    undef $this->array->[$index];
	} elsif ($this->{is_hash}) {
	    my $key = shift;
	    delete $this->hash->{$key};
	}
    }
    sub CLEAR {
	my $this = shift;
	if ($this->{is_array}) {
	    $this->{array} = [];
	} elsif ($this->{is_hash}) {
	    $this->{hash} = {};
	}
    }
    sub PUSH {
	my ($this,@list) = @_;
	my $array = $this->array;
	return push @$array, @list;
    }
    sub POP {
	my $this = shift;
	my $array = $this->array;
	return pop @$array;
    }
    sub SHIFT {
	my $this = shift;
	my $array = $this->array;
	return shift @$array;
    }
    sub UNSHIFT {
	my ($this, @list) = @_;
	my $array = $this->array;
	unshift @$array, @list;
    }
    sub SPLICE {
	my ($this, $offset, $length, @list) = @_;
	$offset ||= 0;
	$length ||= $this->FETCHSIZE - $offset;
	my $array = $this->array;
	return splice @$array, $offset, $length, @list;
    }
    sub array {
	my $this = shift;
	if (!$this->{array}) {
	    $this->{array} = [ $this->{result}->_fetch ];
	}
	$this->{array};
    }
    sub hash {
	my $this = shift;
	if (!$this->{hash}) {
	    $this->{hash} = { $this->{result}->_fetch };
	}
	$this->{hash};
    }
    sub _fetch {
	my $this = shift;
	return $this->{result}->_fetch;
    }
}

{
    package Forks::Super::bg_qx;
    our @ISA = qw(Forks::Super::bg_eval);
    sub TIESCALAR {
	my ($pkg,$command,@other_options) = @_;
	my $result = Forks::Super::LazyEval::bg_qx $command, @other_options;
	my $self = { result => $result };
	bless $self, $pkg;
    }
    sub TIEARRAY {
	my ($pkg,$command,@other_options) = @_;
	my $result = Forks::Super::LazyEval::bg_qx $command, @other_options;
	my $self = { result => $result, is_array => 1 };
	bless $self, $pkg;
    }
    sub TIEHASH {
	my ($pkg,$command,@other_options) = @_;
	my $result = Forks::Super::LazyEval::bg_qx $command, @other_options;
	my $self = { result => $result, is_hash => 1 };
	bless $self, $pkg;
    }
    sub array {
	my $this = shift;
	if (!$this->{array}) {
	    my $eol = quotemeta($/);
	    $this->{array} = [ split m{(?<=$eol)}, $this->{result}->_fetch ];
	}
	$this->{array};
    }
    sub hash {
	my $this = shift;
	if (!$this->{hash}) {
	    my $eol = quotemeta($/);
	    $this->{hash} = { split m{(?<=$eol)}, $this->{result}->_fetch };
	}
	$this->{hash};
    }
}

1;

=head1 NAME

Forks::Super::LazyEval - deferred processing of output from a background proc

=head1 VERSION

0.95

=head1 DESCRIPTION

Implementation of L<Forks::Super::bg_qx|Forks::Super/bg_qx>
and L<Forks::Super::bg_eval|Forks::Super/bg_eval> functions,
and C<Forks::Super::bg_qx> and C<Forks::Super::bg_eval> tied
classes for retrieving results of external commands and
Perl subroutines executed in background processes.
See L<Forks::Super|Forks::Super> for details.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
