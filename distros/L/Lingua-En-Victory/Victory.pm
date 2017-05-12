package Lingua::En::Victory;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::En::Victory ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

our $a = chr(39);
our @template;

# Preloaded methods go here.

sub new {

    my $pkg = shift;
    while (<DATA>) {
	last if /__END__/;
	chomp;
	push @template, $_;
    }

    bless {}, $pkg;

}

sub templates {
    \@template;
}

sub expr {
    my ($self, $template, $W, $L) = @_;

#    warn "$template, $W, $L";
    my $eval = "\$_ = \"$template\""  ;
#    warn $eval;
    eval $eval;
}

sub rand_expr {
    my ($self, $W, $L) = @_;

    my $template = $template[rand @template];
    $self->expr($template, $W, $L);
}

1;
__DATA__
$W spanked $L
$W thumped $L
$W backslapped $L
$W beat the socks off $L
$W hammered $L
$W trounced $L
$W bashed, smashed, thrashed and trashed $L
$W fed $L the agony of defeat
$W slam-dunked $L
$W owned $L
$W opened up a can of whoop-ass on $L
$W sent $L crying home to mama
$W pulverized $L
$W decimated $L
$W destroyed $L
$W played $L like a piano
$W laid $L to waste
$W streamrolled $L
$W put the power-move on $L
$W sent $L to the showers
$W put $L down for the count
$W knocked $L clean out the box
$W owned $L
$W manhandled $L
$W body-slammed $L
$W put the atomic body-drop on $L
$W made $L cry uncle
$W showed $L who${a}s boss
$W gave $L a waxin' and shellackin'
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::En::Victory - Perl extension for egotistically expressing victory.

=head1 SYNOPSIS

  use Lingua::En::Victory;

  my $v = Lingua::En::Victory->new;

  my $templates = $v->templates;
  for my $template (@$templates) {
     print $v->expr($template, $winner, $loser);
     print "\n";
  }

  print $v->rand_expr($template, $winner, $loser) for (1..5);

=head1 ABSTRACT

Lingua::En::Victory is a Perl extension for egotistically expressing victory.


=head1 DESCRIPTION

I developed a gaming site and got a little tired of reporting the results as
"A beat B" so I wrote this module to spice up  the results reporting.

=head2 METHODS

=head3 new()

This must be called first to create a Lingua::En::Victory object for use with
the remaining API calls:

  my $v = Lingua::En::Victory->new;

=head3 templates()

This method returns a reference to the array of templates

  my $templates = $v->templates;

=head3 expr ($template, $winner_name, $loser_name)

This method fills in the given template with the winner and loser name:

  for my $template (@$templates) {
     print $v->expr($template, $winner, $loser);
     print "\n";
  }

=head3 rand_exp ($winner_name, $loser_name)

This method randomly selects one of the templates and fills it in with the
winner and loser name.

=head2 EXPORT

None by default.

=head1 AUTHOR

T. M. Brannon, <tbone@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by T. M. Brannon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
