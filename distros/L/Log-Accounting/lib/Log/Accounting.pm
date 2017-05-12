package Log::Accounting;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %MMAP);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.3';

%MMAP = (
  "Sendmail" => "Log::Accounting::Sendmail",
);


sub new {
  shift;
  my $service = shift;
  my $impl = $MMAP{$service} || do {
    $service =~ s/\W+//;
    "Log::Accounting::$service";
  };
  no strict 'refs';
  unless (exists ${"$impl\::"}{"VERSION"}) {
    eval "require $impl";
  }
  return $impl->new(@_);
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Log::Accounting - Accounting of network services

=head1 SYNOPSIS

  use Log::Accounting;

  my $sm = Log::Accounting->new("Sendmail");
  $sm->addfile($fh);
  $sm->filter("oli@42.nu");
  $sm->group("oli@42.nu");
  %result = $sm->calc();

=head1 DESCRIPTION

Accounting of network services.

=head1 AUTHOR

Oliver Maul, oli@42.nu

=head1 COPYRIGHT

The author of this package disclaims all copyrights and
releases it into the public domain.

=cut
