package MARC::Spec::Parser;

use Carp qw(croak);
use Const::Fast;
use Moo;
use MARC::Spec;
use MARC::Spec::Field;
require MARC::Spec::Subfield;
require MARC::Spec::Indicator;
require MARC::Spec::Comparisonstring;
require MARC::Spec::Subspec;

use namespace::clean;

our $VERSION = '2.0.3';

has spec => (
    is => 'rw',
    required => 1
);

has marcspec => (
    is => 'rwp'
);

const my $FIELDTAG => q{(?<tag>(?:[a-z0-9\.]{3,3}|[A-Z0-9\.]{3,3}|[0-9\.]{3,3}))};
const my $POSITIONORRANGE => q{(?:(?:(?:[0-9]+|#)\-(?:[0-9]+|#))|(?:[0-9]+|#))};
const my $INDEX => qq{(?:\\[(?<index>$POSITIONORRANGE)\\])?};
const my $CHARPOS => qq{(?:\\/(?<charpos>$POSITIONORRANGE))?};
const my $INDICATORPOS => q{(?:\^(?<indicatorpos>[12]))};
const my $SUBSPECS => q{(?<subspecs>(?:\\{.+?(?<!(?<!(\$|\\\))(\$|\\\))\\})+)?};
const my $SUBFIELDS => q{(?<subfields>\$.+)};
const my $FIELD => qq{(?<field>$FIELDTAG$INDEX)};
const my $MARCSPEC => qr/^(?<marcspec>$FIELD(?:$SUBFIELDS|(?:$INDICATORPOS|$CHARPOS)$SUBSPECS))/s;
const my $SUBFIELDRANGE => q{(?<range>(?:[0-9a-z]\-[0-9a-z]))};
const my $SUBFIELDTAG => q{(?<code>[\!-\?\[-\\{\\}-~])};
const my $SUBFIELD => qr/(?<subfield>\$(?:$SUBFIELDRANGE|$SUBFIELDTAG)$INDEX$CHARPOS$SUBSPECS)/s;
const my $LEFTSUBTERM => q{^(?<left>(?:\\\(?:(?<=\\\)[\!\=\~\?]|[^\!\=\~\?])+)|(?:(?<=\$)[\!\=\~\?]|[^\!\=\~\?])+)?};
const my $OPERATOR => q{(?<operator>\!\=|\!\~|\=|\~|\!|\?)};
const my $SUBTERMS => qq{(?:$LEFTSUBTERM$OPERATOR)?(?<right>.+)}.q{$};
const my $SUBSPEC => qr/(?:\{(.+?)\})/s;
const my $UNESCAPED => qr/(?<![\\\\\$])[\{\}]/s;

const my $MIN_LENGTH_FIELD => 3;
const my $MIN_LENGTH_SUBFIELD => 2;
const my $NO_LENGTH => -1;
const my $ERROR => 'Only one of characterSpec, subfieldSpec or indicatorSpec is allowed.';

my %cache;

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args % 2 == 1) { unshift @args, "spec" }
    return { @args };
}

sub BUILD {
    my ($self) = @_;
    my ($indicator, $subspecs, $field, $ms);
    
    _do_checks($self->spec, $MIN_LENGTH_FIELD);

    $self->spec =~ $MARCSPEC;
    
    %{$self->{_parsed}} = %+;

    if(!$self->{_parsed}->{tag}) {
        _throw("For fieldtag only '.', digits and lowercase alphabetic or digits and upper case alphabetics characters are allowed.", $self->spec);
    }

    if( length $self->{_parsed}->{marcspec}  != length $self->spec ) {
        _throw('Detected useless data fragment or invalid field spec.', $self->spec);
    }
    
    # create a new Field
    $field = MARC::Spec::Field->new($self->{_parsed}->{tag});

    if(defined $self->{_parsed}->{charpos}) {

        if(defined $self->{_parsed}->{subfields}) {
            _throw($ERROR, $self->spec);
        }
        $field->set_char_start_end($self->{_parsed}->{charpos});
    }
    
    if(defined $self->{_parsed}->{index}) {
        $field->set_index_start_end($self->{_parsed}->{index});
    }
    
    $self->{field_base} = $field->base;

    $ms = MARC::Spec->new($field);

    if(defined $self->{_parsed}->{indicatorpos}) {
        if(defined $self->{_parsed}->{charpos}) {
            _throw($ERROR, $self->spec);
        }
        $indicator = MARC::Spec::Indicator->new($self->{_parsed}->{indicatorpos});

        $ms->indicator($indicator);

    } elsif($self->{_parsed}->{subfields}) {
        if(defined $self->{_parsed}->{indicatorpos}) {
            _throw($ERROR, $self->spec);
        }
        my $subfields = $self->_match_subfields();
        $ms->add_subfields($subfields);
    }
    
    if($self->{_parsed}->{subspecs}) {
        $subspecs = $self->_match_subspecs($self->{_parsed}->{subspecs});
        if(defined $indicator) {
            $self->_populate_subspecs($indicator, $subspecs, [$field->base, $indicator->base]);
        } else {
            $self->_populate_subspecs($field, $subspecs, [$field->base]);
        }
    }

    $self->_set_marcspec($ms);
}

sub _populate_subspecs {
    my ($self, $spec, $subspecs, $base) = @_;
    foreach my $subspec (@{$subspecs}) {
        # check if array length is above 1
        if(1 < scalar @{$subspec}) {
            # alternatives to array (OR)
            my @or = ();
            foreach my $or_subspec (@{$subspec}) {
                push @or, $self->_match_subterms($or_subspec, $base);
            }
            $spec->add_subspecs([\@or]);
        }
        else {
            $spec->add_subspec( $self->_match_subterms($subspec->[0], $base ) );
        }
    }
}

sub _match_subfields {
    my ($self) = @_;

    _do_checks($self->{_parsed}->{subfields}, $MIN_LENGTH_SUBFIELD);

    my $subfields = [];
    my $i = 0;
    while($self->{_parsed}->{subfields} =~ /$SUBFIELD/g) {
        if(defined $+{range}) {
            my $from = substr $+{range},0,1;
            my $to = substr $+{range},2,1;
            for my $code ( $from .. $to) {
                push @{$subfields}, $self->_create_subfield($code,%+);
            }
        } else {
            push @{$subfields}, $self->_create_subfield(undef,%+);
        }
        $i++;
    }

    if(0 == $i) {
        _throw("Invalid subfield spec detected.", $self->{_parsed}->{subfields});
    }

    return $subfields;
}

sub _create_subfield {
    my ($self,$code,%args) = @_;
    # create a new Subfield
    my $subfield = MARC::Spec::Subfield->new($code // $args{code});

    if(defined $args{index}) {
        $subfield->set_index_start_end($args{index});
    } 

    if(defined $args{charpos}) {
        $subfield->set_char_start_end($args{charpos});
    }

    # handle subspecs
    if(defined $args{subspecs}) {
        my $subfield_subspecs = $self->_match_subspecs($args{subspecs});
        $self->_populate_subspecs($subfield, $subfield_subspecs, [$self->{field_base}, $subfield->base]);
    }
    return $subfield;
}

sub _match_subspecs {
    my ($self, $subspecs) = @_;
    my @subspecs;

    foreach ($subspecs =~ /$SUBSPEC/g) {
        push @subspecs, [split(/(?<!\\)\|/, $_)];
    }
    return \@subspecs;
}

sub _match_subterms {
    my ($self,$subTerms,$context) = @_;

    if($subTerms =~ $UNESCAPED) {
        _throw("Unescaped character detected.", $subTerms);
    }

    if($subTerms !~ /$SUBTERMS/sg) {
        _throw("Assuming invalid spec.", $subTerms);
    }

    # create a new Subspec
    my $subSpec = MARC::Spec::Subspec->new;

    foreach my $side (('left', 'right')) {
        if(defined $+{$side}) {
            if('\\' ne substr $+{$side},0,1) {
                my $spec = _spec_context($+{$side},$context);
                # this prevents the spec parsed again
                if($cache{$spec}) {
                    $subSpec->$side( $cache{$spec} );
                } else {
                    $subSpec->$side( MARC::Spec::Parser->new($spec)->marcspec );

                    $cache{$spec} = $subSpec->$side;
                }
            } else {
                $subSpec->$side( MARC::Spec::Comparisonstring->new(substr $+{$side},1) );
            }
        } elsif($side eq 'left') {
            my $spec = _spec_context(@{$context}[$#{$context}],$context);
            if($cache{$spec}) {
                $subSpec->left( $cache{$spec} );
            } else {
                $subSpec->left( MARC::Spec::Parser->new($spec)->marcspec );
                $cache{$spec} = $subSpec->left;
            }
        } else {
            _throw("Right hand subTerm is missing.", $subTerms);
        }
    }

    if(defined $+{operator}) { $subSpec->operator( $+{operator} )}

    return $subSpec;
}

sub _spec_context {
    my ($spec, $context) = @_;

    my $fieldContext = @{$context}[0];
    my $fullcontext = join '', @{$context};

    if($spec eq $fullcontext) { return $spec }

    my $firstChar = substr $spec,0,1;
    if($firstChar eq '^') {
        my $refPos = index $fullcontext, $firstChar;
        if(0 <= $refPos) {
            return substr($fullcontext,0,$refPos)."$spec";
        }

        return "$fieldContext"."$spec";
    }
    
    if($firstChar eq '$') { return $fieldContext.$spec }
    
    if($firstChar =~ /\[|\//) {
        my $refPos = rindex $fullcontext, $firstChar;

        if(0 <= $refPos) {
            if('$' ne substr $fullcontext,$refPos - 1,1) {
                return substr($fullcontext,0,$refPos)."$spec";
            }
        }
        return "$fullcontext"."$spec";
    }

    return $spec;
}

sub _do_checks {
    my ($spec, $min_length) = @_;

    if(ref \$spec ne 'SCALAR') {
        _throw("Argument must be of type SCALAR.", ref \$spec);
    }

    if($spec =~ /\s/s) {
        _throw("Whitespaces are not allowed.", $spec);
    }

    if($min_length > length $spec) {
        _throw("Spec must be at least ".$min_length." chracters long.", $spec);
    }

    return;
}

sub _throw {
    my ($message, $hint) = @_;
    croak 'MARCspec Parser exception. '.$message.' Tried to parse: '.$hint;
}

1;
__END__

=encoding utf-8

=head1 NAME

MARC::Spec::Parser - parses a MARCspec as string

=head1 SYNOPSIS

    use MARC::Spec::Parser;
    
    my $parser = MARC::Spec::Parser->new('245$a');
    
    my $ms = $parser->marcspec;

    say ref $ms; # MARC::Spec

=head1 DESCRIPTION

MARC::Spec::Parser parses a MARCspec as string into a L<MARC::Spec|MARC::Spec>.
L<MARC::Spec|MARC::Spec> is a L<MARCspec - A common MARC record path language|http://marcspec.github.io/MARCspec/> parser and validator.

=head1 METHODS

=head2 new(Str)

Create a new MARC::Spec::Parser instance. Parameter must be a 
MARCspec as string.

=head1 ATTRIBUTES

=head2 spec

Obligatory. The parameter string the MARC::Spec::Parser was instantiated with.

=head2 marcspec

Instance of L<MARC::Spec|MARC::Spec>.

=head1 AUTHOR

Carsten Klee C<< <klee at cpan.org> >>

=head1 CONTRIBUTORS

=over

=item * Johann Rolschewski, C<< <jorol at cpan> >>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Carsten Klee.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs to L<https://github.com/MARCspec/MARC-Spec/issues|https://github.com/MARCspec/MARC-Spec/issues>

=head1 SEE ALSO

=over

=item * L<MARC::Spec|MARC::Spec>

=item * L<MARC::Spec::Field|MARC::Spec::Field>

=item * L<MARC::Spec::Subfield|MARC::Spec::Subfield>

=item * L<MARC::Spec::Indicator|MARC::Spec::Indicator>

=item * L<MARC::Spec::Subspec|MARC::Spec::Subspec>

=item * L<MARC::Spec::Structure|MARC::Spec::Structure>

=item * L<MARC::Spec::Comparisonstring|MARC::Spec::Comparisonstring>

=back

=cut
