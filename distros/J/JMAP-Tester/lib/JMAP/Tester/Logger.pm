use v5.14.0;
package JMAP::Tester::Logger 0.104;

use Moo::Role;

use JMAP::Tester::LogWriter;
use Params::Util qw(_CODELIKE _HANDLE _SCALAR0);

use namespace::clean;

has writer => (
  is  => 'ro',
  isa => sub {
    die "no writer provided" unless $_[0];
    die "writer provided can't be called as code" unless $_[0]->does('JMAP::Tester::LogWriter');
  },
  coerce   => sub {
    my $value = $_[0];
    return JMAP::Tester::LogWriter::Code->new({ code => $value })
      if _CODELIKE($value);

    return JMAP::Tester::LogWriter::Handle->new({ handle => $value })
      if _HANDLE($value);

    return JMAP::Tester::LogWriter::Code->new({ code => sub{} })
      if _SCALAR0($value) && ! defined $$value;

    if (defined $value && ! ref $value && length $value) {
      if ($value =~ /\A-([1-9][0-9]*)\z/) {
        open my $handle, '>&', "$1"
          or die "can't dup fd $1 for logger output: $!";
        $handle->autoflush(1);
        return JMAP::Tester::LogWriter::Handle->new({ handle => $handle });
      }

      return JMAP::Tester::LogWriter::Filename->new({
        filename_template => $value
      });
    }

    return $value;
  },
  required => 1,
);

sub write {
  my ($self, $string) = @_;
  $self->writer->write( $string );
}

requires 'log_jmap_request';
requires 'log_jmap_response';

requires 'log_upload_request';
requires 'log_upload_response';

requires 'log_download_request';
requires 'log_download_response';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Logger

=head1 VERSION

version 0.104

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
