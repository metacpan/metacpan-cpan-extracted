package Evo::Test::Mock;
use Evo '-Class *; -Export; Carp croak; -Lib eval_want strict_opts; /::Call';
use Hash::Util::FieldHash 'fieldhash';

fieldhash my %REG;

has 'original_sub';
has 'original_name';
has 'calls';
has 'sub';

our $ORIGINAL;

sub get_original() : prototype() : Export {
  $ORIGINAL or die "Not in mocked subroutine";
}

sub call_original : Export { get_original->(@_); }

sub create_mock ($me, $name, @args) {
  my %args;
  %args = @args == 1 ? (patch => $args[0]) : @args;
  my ($patch, $rethrow) = strict_opts \%args, [qw(patch rethrow)], 2;

  no strict 'refs';    ## no critic
  my $orig = *{$name}{CODE} or die "No sub $name";
  croak "$name was already mocked" if $REG{$orig};

  my $mock_sub = ref $patch eq 'CODE' ? $patch : $patch ? sub { call_original(@_) } : sub { };

  my $calls = [];
  my $sub   = sub {
    local $ORIGINAL = $orig;
    my $rfn  = eval_want wantarray, @_, $mock_sub;
    my $err  = $@;
    my $call = Evo::Test::Call->new(args => \@_, exception => $err, result_fn => $rfn);
    push $calls->@*, $call;
    croak $err if !$rfn && $rethrow;
    return unless $rfn;
    $rfn->();
  };

  my $mock = $me->new(original_sub => $orig, original_name => $name, sub => $sub, calls => $calls);

  no warnings 'redefine';
  $REG{$sub}++;
  *{$name} = $sub;
  $mock;
}

sub get_call ($self, $n) {
  return unless exists $self->calls->[$n];
  $self->calls->[$n];
}

sub DESTROY($self) {
  ## no critic;
  no strict 'refs';
  no warnings 'redefine';
  *{${\$self->original_name}} = $self->original_sub;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Test::Mock

=head1 VERSION

version 0.0403

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
