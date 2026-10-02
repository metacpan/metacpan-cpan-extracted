package Langertha::Raider::CLI::PromptBuilder;
# ABSTRACT: Internal prompt-builder sub-agent of the raider CLI (/prompt)
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use utf8;
use Langertha::Raider;


has app => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI',
  required => 1,
);

has output => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI::Output',
  required => 1,
);

has in => (
  is      => 'ro',
  default => sub { \*STDIN },
);

sub _mission {
  my ( $self, $file, $label ) = @_;
  my $current = -f $file ? $file->slurp_utf8 : '(no '.$label.' yet — Langertha default persona is active)';
  return <<"EOM";
You are the raider prompt-builder. Your only job right now is to help the user
craft a $label file that customizes the persona and instructions of
"raider" (the CLI agent; the default persona is Langertha, a viking
shield-maiden).

Current $label content:
---
$current
---

Rules:
  - Converse naturally with the user. Ask what persona, tone, rules or
    constraints they want.
  - When the user is satisfied, use write_file to save to:
      @{[ $file ]}
  - After writing, confirm what you saved and tell the user they can type
    "/done" to return to the main agent (the main agent will auto-reload the
    new persona).
  - If the user asks you to cancel, do not write anything; just confirm.
  - Do NOT call bash or any tool other than read_file / write_file / edit_file
    during this session.
EOM
}


sub run {
  my ($self) = @_;
  my $app  = $self->app;
  my $out  = $self->output;
  my $instructions = $app->instructions;
  my $file = $instructions->file;

  my $builder_raider = Langertha::Raider->new(
    engine         => $app->_engine,
    mission        => $self->_mission($file, $instructions->label),
    max_iterations => 20,
  );

  $out->say_meta('entering prompt-builder. /done to return, /cancel to discard.');
  my $in = $self->in;

  while (1) {
    $out->emit('raider:prompt> ');
    my $line = <$in>;
    last unless defined $line;
    chomp $line;
    $line =~ s/^\s+|\s+$//g;
    next unless length $line;

    if ($line =~ m{^/(?:done|back|exit|quit)$}i) {
      my $new = $app->reload_mission;
      $out->say_meta('prompt-builder finished. mission reloaded ('.length($new).' chars).');
      last;
    }
    if ($line =~ m{^/cancel$}i) {
      $out->say_meta('prompt-builder cancelled.');
      last;
    }

    my $f = $builder_raider->raid_f($line);
    $app->loop->await($f);
    my $r = eval { $f->get };
    if ($@) {
      my $err = $@; chomp $err;
      $out->say_error($err);
      next;
    }
    $out->say_agent("$r");
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::PromptBuilder - Internal prompt-builder sub-agent of the raider CLI (/prompt)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    Langertha::Raider::CLI::PromptBuilder->new(app => $app, output => $out)->run;

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The C</prompt> REPL command and C<--customize-prompt>: a second raider on the
same engine whose only job is to write the project instructions file with
the user: the one in use (L<Langertha::Raider::Instructions/file>), so
F<.raider/instructions.md> when it exists, else F<.raider.md>; it never
creates F<.raider/instructions.md>. It reads lines from L</in> until
C</done> (reload the mission and return) or C</cancel>.

=head2 app

The L<Langertha::Raider::CLI> whose instructions file is edited. Required.

=head2 output

The L<Langertha::Raider::CLI::Output> to print to. Required.

=head2 in

Filehandle the conversation is read from. Defaults to C<STDIN>.

=head2 run

Runs the prompt-builder conversation until C</done>, C</cancel> or the end
of L</in>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI::Commands>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
