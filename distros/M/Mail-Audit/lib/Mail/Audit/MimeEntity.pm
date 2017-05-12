use strict;
package Mail::Audit::MimeEntity;
{
  $Mail::Audit::MimeEntity::VERSION = '2.228';
}
# ABSTRACT: a Mail::Internet-based Mail::Audit object

use File::Path;
use Mail::Audit::Util::Tempdir;
use MIME::Parser;
use MIME::Entity;
use Mail::Audit::MailInternet;
use parent qw(Mail::Audit MIME::Entity);

my $parser;

my @to_rmdir;

sub _autotype_new {
  my $class        = shift;
  my $mailinternet = shift;
  my $options      = shift;

  $parser = MIME::Parser->new();

  $parser->ignore_errors(1);

  my $dir;
  if ($options->{output_to_core}) {
    $parser->output_to_core($options->{output_to_core});
  } else {
    $dir = Mail::Audit::Util::Tempdir->new;
    $mailinternet->_log(3, "created temporary directory " . $dir->name);
    $parser->output_under($dir->name);
  }

  # MIME::Parser has options like extract_nested_messages which are set via
  # option-methods.
  # we'll hand them along here so that if you call Mail::Audit(mimeoptions =>
  # { foo => 1 })
  # the corresponding parser option is set, with $parser->foo(1).
  foreach my $option (keys %$options) {
    next if $option eq "output_to_core";
    if ($parser->can($option)) { $parser->$option($options->{$option}); }
  }

  my $self = $parser->parse_data(
    [ @{ $mailinternet->head->header }, "\n", @{ $mailinternet->body } ]
  );

  # I am so, so sorry that this sort of thing is needed.
  # -- rjbs, 2007-06-14
  $self->{_log} = $mailinternet->{_log};

  unless ($options->{output_to_core}) {
    my $output_dir = $parser->filer->output_dir;
    $mailinternet->_log(3, "outputting under $output_dir");
  }

  # Augh!  These guts are so foul and convoluted.  I feel like I might as well
  # be using guids.  Whatever, this will solve the tempdir-lingers-too-long
  # problem. -- rjbs, 2006-10-31
  $self->{'__Mail::Audit::MimeEntity/tempdir'} = $dir;
  bless($self, $class);
  return $self;
}


sub parser { $parser ||= MIME::Parser->new(); }

sub is_mime { 1; }

1;

__END__

=pod

=head1 NAME

Mail::Audit::MimeEntity - a Mail::Internet-based Mail::Audit object

=head1 VERSION

version 2.228

=head2 parser

This method returns the message's own MIME::Parser.

This method is B<very> likely to go away.

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Meng Weng Wong

=item *

Ricardo SIGNES

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
