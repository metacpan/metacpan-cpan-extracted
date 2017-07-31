package HTML::FormHandler::TraitFor::Types;
# ABSTRACT: types used internally in FormHandler
$HTML::FormHandler::TraitFor::Types::VERSION = '0.40068';
use Moose::Role;
use Moose::Util::TypeConstraints;

subtype 'HFH::ArrayRefStr'
  => as 'ArrayRef[Str]';

coerce 'HFH::ArrayRefStr'
  => from 'Str'
  => via {
         if( length $_ ) { return [$_] };
         return [];
     };

coerce 'HFH::ArrayRefStr'
  => from 'Undef'
  => via { return []; };

subtype 'HFH::SelectOptions'
  => as 'ArrayRef[HashRef]';

coerce 'HFH::SelectOptions'
  => from 'ArrayRef[Str]'
  => via {
         my @options = @$_;
         die "Options array must contain an even number of elements"
            if @options % 2;
         my $opts;
         push @{$opts}, { value => shift @options, label => shift @options } while @options;
         return $opts;
     };

coerce 'HFH::SelectOptions'
  => from 'ArrayRef[ArrayRef]'
  => via {
         my @options = @{ $_[0][0] };
         my $opts;
         push @{$opts}, { value => $_, label => $_ } foreach @options;
         return $opts;
     };

no Moose::Util::TypeConstraints;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::TraitFor::Types - types used internally in FormHandler

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
