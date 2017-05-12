# PerlCode; allow arbitrary perl code be embedded in a WebMake file.

package HTML::WebMake::PerlCode;

use Carp;
use strict;

use HTML::WebMake::Main;
use HTML::WebMake::PerlCodeLibrary;

use vars	qw{
  	@ISA $CAN_USE_IO_STRING
	$GlobalSelf @PrevSelves %SORT_SUBS
};

@ISA = qw();

###########################################################################

sub new ($$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main) = @_;

  my $self = {
    'main'		=> $main,
  };
  bless ($self, $class);
  $self;
}

sub can_use_io_string {
  if (defined $CAN_USE_IO_STRING) { return $CAN_USE_IO_STRING; }

  $CAN_USE_IO_STRING = 0;
  eval q{
    require IO::String; $CAN_USE_IO_STRING = 1; 1;
  };

  return $CAN_USE_IO_STRING;
}

sub new_io_string {
  eval q{
    return new IO::String ();
  };
}

sub dbg { HTML::WebMake::Main::dbg (@_); }

# -------------------------------------------------------------------------

sub interpret {
  my ($self, $type, $str, $defunderscoreval) = @_;
  my ($ret);

  local ($_) = $defunderscoreval;
  if (!defined ($_)) { $_ = ''; }

  if ($self->{main}->{paranoid}) {
    return "\n(Paranoid mode on - perl code evaluation prohibited.)\n";
  }

  # note that both $self and $_ are available from within evaluated
  # perl code.

  $self->enter_perl_call();

  if ($type ne "perlout") {
    $ret = eval 'package main; '.$str;

  } else {
    if (!can_use_io_string()) {
      warn "<{perlout}> code failed: IO::String module not available\n";

    } else {
      my $outhandle = new_io_string();

      $ret = eval 'package main; select $outhandle; '.$str;

      if (defined($ret)) {
	$ret = ${$outhandle->string_ref()};
	chomp $ret;
      }

      select STDOUT;
      $outhandle = undef;
    }
  }

  $self->exit_perl_call();

  if (!defined $ret) {
    warn "<{perl}> code failed: $@\nCode: $str\n";
    $ret = '';
  }
  $ret;
}

sub enter_perl_call {
  my ($self) = @_;
  push (@PrevSelves, $GlobalSelf); $GlobalSelf = $self;
}

sub exit_perl_call {
  my ($self) = @_;
  $GlobalSelf = pop (@PrevSelves);
}

# -------------------------------------------------------------------------

# get and eval() a sort subroutine for the given sorting criteria.
# stores cached sort sub { } refs in the %SORT_SUBS global array to
# avoid re-evaluating the same piece of perl code repeatedly.
# 
sub get_sort_sub {
  my ($self, $sortstr) = @_;    

  if (!defined $SORT_SUBS{$sortstr}) { 
    my $sortsubstr = $self->{main}->{metadata}->string_to_sort_sub ($sortstr);
    my $sortsub = eval $sortsubstr;
    $SORT_SUBS{$sortstr} = $sortsub;
  }
  
  $SORT_SUBS{$sortstr}; 
}

# -------------------------------------------------------------------------

1;
