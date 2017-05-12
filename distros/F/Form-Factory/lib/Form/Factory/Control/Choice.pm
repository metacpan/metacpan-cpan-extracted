package Form::Factory::Control::Choice;
$Form::Factory::Control::Choice::VERSION = '0.022';
use Moose;

# ABSTRACT: Helper class for tracking choices


has label => (
    is        => 'ro',
    isa       => 'Str',
);


has value => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

sub BUILDARGS {
    my $class = shift;
    my %args;

    if (@_ == 1 and ref $_[0]) {
        %args = %{ $_[0] };
    }
    elsif (@_ == 1) {
        $args{value} = $_[0];
    }
    elsif (@_ == 2) {
        $args{value} = $_[0];
        $args{label} = $_[1];
    }
    else {
        %args = @_;
    }

    $args{label} = $args{value} unless defined $args{label};

    return $class->SUPER::BUILDARGS(%args);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Choice - Helper class for tracking choices

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  my $foo = Form::Factory::Control::Choice->new('foo');
  my $bar = Form::Factory::Control::Choice->new('bar' => 'Bar');
  my $baz = Form::Factory::Control::Choice->new(
      label => 'Baz',
      value => 'baz',
  );
  my $qux = Form::Factory::Control::Choice->new({
      label => 'Qux',
      value => 'qux',
  });

=head1 DESCRIPTION

These objects represent a single choice for a list or popup box. Each choice has a label and a value. The constructor is flexible to allow the following uses:

  my $choice = Form::Factory::Control::Choice->new($value) # $label = $value
  my $choice = Form::Factory::Control::Choice->new($value => $label);
  my $choice = Form::Factory::Control::Choice->new(
      label => $label,
      value => $value,
  );
  my $choice = Form::Factory::Control::Choice->new({
      label => $label,
      value => $value,
  });

If C<$value> and C<$label> are the same, all of those calls are identical.

=head1 ATTRIBUTES

=head2 label

The label to give the choice.

=head2 value

The value of the choice.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
