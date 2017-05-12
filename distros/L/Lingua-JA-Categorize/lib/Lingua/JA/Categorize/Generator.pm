package Lingua::JA::Categorize::Generator;
use strict;
use warnings;
use Lingua::JA::Expand;
use base qw( Lingua::JA::Categorize::Base );

__PACKAGE__->mk_accessors($_) for qw( brain expander );

sub generate {
    my $self       = shift;
    my $categories = shift;
    my $brain      = shift;
    my $save_file  = shift;
    my $c          = $self->context;
	print $c->config->{yahoo_api_appid};<>;
    my $expander   = Lingua::JA::Expand->new(
        yahoo_api_appid   => $c->config->{yahoo_api_appid},
        yahoo_api_premium => 1
    );

    while ( my ( $label, $ref ) = each %$categories ) {
        my $weight  = $ref->{weight};
        my @keyword = @{ $ref->{keyword} };
        for my $keyword (@keyword) {
            my $word_set = $expander->expand($keyword);
            $brain->add_instance(
                attributes => $word_set,
                label      => $label,
            );
            if ( $weight > 1 ) {
                for ( 1 .. $weight ) {
                    $brain->add_instance(
                        attributes => { dummy => 0 },
                        label      => $label,
                    );
                }
            }
        }
        $brain->train;
        print $label, "\n";
    }
    $brain->save_state($save_file) if $save_file;
}

1;
__END__

=head1 NAME

Lingua::JA::Categorize::Generator - generator module 

=head1 SYNOPSIS

  use Lingua::JA::Categorize::Generator;

  # generate
  my $c = Lingua::JA::Categorize::Generator->new;
  $generator->generate($category_conf);

=head1 DESCRIPTION

Lingua::JA::Categorize::Generate is a generate module.

=head1 METHODS

=head2 generate

=head2 brain

=head2 expander

=head1 AUTHOR

takeshi miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
