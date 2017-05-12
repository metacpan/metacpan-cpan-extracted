package Git::Class::Role::Execute;

use Moo::Role; with qw/
  Git::Class::Role::Error
  Git::Class::Role::Cwd
/;
use Capture::Tiny qw(capture tee);
use Scope::Guard ();
use Path::Tiny ();

sub _execute {
  my ($self, @args) = @_;

  @args = map { _quote($_) } @args;

  if ($ENV{GIT_CLASS_TRACE}) {
    print STDERR join ' ', @args, "\n";
  }

  my ($out, $err) = do {
    # Capture::Tiny may confuse your web apps, so use it sparingly.
    if (!defined wantarray or $self->no_capture) {
      my $cwd = Path::Tiny->cwd;
      my $guard = Scope::Guard::guard { chdir $cwd };
      chdir $self->_cwd if $self->_cwd;
      system(@args);
      return ('', $?);
    }
    else {
      local *capture = *tee if $self->is_verbose;
      capture {
        my $cwd = Path::Tiny->cwd();
        my $guard = Scope::Guard::guard { chdir $cwd };
        chdir $self->_cwd if $self->_cwd;
        system(@args);
      };
    }
  };

  $self->_error($err) if $err;

  wantarray ? split /\n/, $out : $out;
}

sub _get_options {
  my ($self, @args) = @_;

  my (%options, @left);
  foreach my $arg (@args) {
    if (ref $arg eq 'HASH') {
      %options = (%options, %{ $arg });
    }
    else {
      push @left, $arg;
    }
  }
  return (\%options, @left);
}

sub _prepare_options {
  my ($self, $options) = @_;

  my @list;
  foreach my $key (sort keys %{ $options }) {
    my $value = $options->{$key};
       $value = '' unless defined $value;
    $key =~ s/_/\-/g;
    if (length $key == 1) {
      unshift @list, "-$key", ($value ne '' ? $value : ());
    }
    else {
      unshift @list, "--$key".(($value ne '') ? "=$value" : '');
    }
  }
  return @list;
}

sub _quote {
  my $value = shift;

  return '' unless defined $value;
  return $$value if ref $value eq 'SCALAR';

  my $option_name;
  if ($value =~ s/^(\-\-[\w\-]+=)//) {
    $option_name = $1;
  }
  my $org_value = $value;
  if ($^O eq 'MSWin32') {
    if ($org_value =~ /[\s^"<>&|!\(\)=;,]/) {
      $value =~ s/\%/^\%/g;
      $value =~ s/"/"""/g;
      $value = qq{"$value"};
    }
  }
  else {
    require String::ShellQuote;
    $value = String::ShellQuote::shell_quote_best_effort($value);
  }
  $value = $option_name . $value if $option_name;

  return $value;
}

1;

__END__

=head1 NAME

Git::Class::Role::Execute

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
