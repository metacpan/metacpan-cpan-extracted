package JSON::Schema::AsType::Annotations;
our $AUTHORITY = 'cpan:YANICK';
$JSON::Schema::AsType::Annotations::VERSION = '1.0.0';
# ABSTRACT: Manage scope annotations for schema


use 5.42.0;
use warnings;

use feature qw/ signatures module_true /;

use List::Util  qw/ uniq /;
use Hash::Merge qw/ merge /;

use base qw/ Exporter::Tiny /;

our @EXPORT = qw/ add_annotation annotation_scope annotations annotation_for
  annotation_properties annotation_items annotation_merge /;

our %ANNOTATIONS;

sub annotations {
    return {%ANNOTATIONS};
}

sub annotation_scope($sub) {
    local %ANNOTATIONS = ();
    return $sub->();
}

sub annotation_for($cat) {
    return $ANNOTATIONS{$cat} // [];
}

sub annotation_properties() {
    return uniq map { annotation_for($_)->@* }
      qw/ properties patternProperties additionalProperties unevaluatedProperties /;

}

sub annotation_items() {
    return uniq map { annotation_for($_)->@* }
      qw/ items patternItems prefixItems unevaluatedItems contains /;

}

sub add_annotation( $category, @values ) {
    $ANNOTATIONS{$category} //= [];
    $ANNOTATIONS{$category} = [ uniq $ANNOTATIONS{$category}->@*, @values ];
}

sub annotation_merge($to_merge) {
    %ANNOTATIONS = merge( \%ANNOTATIONS, $to_merge )->%*;
    return annotations();
}

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Annotations - Manage scope annotations for schema

=head1 VERSION

version 1.0.0

=head1 DESCRIPTION 

Internal module for L<JSON::Schema:::AsType>. 

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
