package KinoSearch1::Analysis::Analyzer;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        language => '',
    );
}

# usage: $token_batch = $analyzer->analyze($token_batch);
sub analyze { return $_[1] }

1;

__END__

=head1 NAME

KinoSearch1::Analysis::Analyzer - base class for analyzers

=head1 SYNOPSIS

    # abstract base class -- you probably want PolyAnalyzer, not this.

=head1 DESCRIPTION

In KinoSearch1, an Analyzer is a filter which processes text, transforming it
from one form into another.  For instance, an analyzer might break up a long
text into smaller pieces (L<Tokenizer|KinoSearch1::Analysis::Tokenizer>), or it
might convert text to lowercase
(L<LCNormalizer|KinoSearch1::Analysis::LCNormalizer>).

=head1 METHODS

=head2 analyze (EXPERIMENTAL)

    $token_batch = $analyzer->analyze($token_batch);

All Analyzer subclasses provide an C<analyze> method.  C<analyze()>
takes a single L<TokenBatch|KinoSearch1::Analysis::TokenBatch> as input, and it
returns a TokenBatch, either the same one (probably transformed in some way),
or a new one.

=head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

=head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

=cut

