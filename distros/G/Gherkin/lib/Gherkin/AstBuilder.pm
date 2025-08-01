package Gherkin::AstBuilder;
$Gherkin::AstBuilder::VERSION = '33.1.0';
use strict;
use warnings;
use Scalar::Util qw(reftype);

use Cucumber::Messages;

use Gherkin::Exceptions;
use Gherkin::AstNode;

sub new {
    my $class = shift;
    my ($id_generator) = @_;

    my $id_counter = 0;
    my $self  = bless {
        stack         => [],
        comments      => [],
        id_generator  => $id_generator // sub {
            return $id_counter++;
        },
        uri           => '',
    }, $class;
    $self->reset;
    return $self;
}

# Simple builder sugar
sub ast_node { Gherkin::AstNode->new( $_[0] ) }

sub reset {
    my $self  = shift;
    my ($uri) = @_;
    $self->{'stack'}    = [ ast_node('None') ];
    $self->{'comments'} = [];
    $self->{'uri'}      = $uri;
}

sub current_node {
    my $self = shift;
    return $self->{'stack'}->[-1];
}

sub start_rule {
    my ( $self, $rule_type ) = @_;
    push( @{ $self->{'stack'} }, ast_node($rule_type) );
}

sub end_rule {
    my ( $self, $rule_type ) = @_;
    my $node = pop( @{ $self->{'stack'} } );
    $self->current_node->add( $node->rule_type, $self->transform_node($node) );
}

sub build {
    my ( $self, $token ) = @_;
    if ( $token->matched_type eq 'Comment' ) {
        push @{ $self->{'comments'} },
            Cucumber::Messages::Comment->new(
                location => $self->get_location($token),
                text     => $token->matched_text
            );
    } else {
        $self->current_node->add( $token->matched_type, $token );
    }
}

sub get_result {
    my $self = shift;
    return $self->current_node->get_single('GherkinDocument');
}

sub get_location {
    my ( $self, $token, $column ) = @_;

    use Carp qw/confess/;
    confess "What no token?" unless $token;

    return Cucumber::Messages::Location->new(
        line   => $token->location->{'line'},
        column => $column // $token->location->{'column'}
        );
}

sub get_tags {
    my ( $self, $node ) = @_;

    my $tags_node = $node->get_single('Tags') || return [];
    my @tags;

    for my $token ( @{ $tags_node->get_tokens('TagLine') } ) {
        for my $item ( @{ $token->matched_items } ) {
            push @tags,
                Cucumber::Messages::Tag->new(
                    id       => $self->next_id,
                    location => $self->get_location( $token, $item->{'column'} ),
                    name     => $item->{'text'}
                );
        }
    }

    return \@tags;
}

sub get_table_rows {
    my ( $self, $node ) = @_;
    my @rows;

    for my $token ( @{ $node->get_tokens('TableRow') } ) {
        push @rows, Cucumber::Messages::TableRow->new(
            id       => $self->next_id,
            location => $self->get_location($token),
            cells    => $self->get_cells($token)
            );
    }

    $self->ensure_cell_count( \@rows );
    return \@rows;
}

sub ensure_cell_count {
    my ( $self, $rows ) = @_;
    return unless @{$rows};

    my $cell_count;

    for my $row (@{$rows}) {
        my $this_row_count = @{ $row->cells };
        $cell_count = $this_row_count unless defined $cell_count;
        unless ( $cell_count == $this_row_count ) {
            Gherkin::Exceptions::AstBuilder->throw(
                "inconsistent cell count within the table",
                $row->location );
        }
    }
}

sub get_cells {
    my ( $self, $table_row_token ) = @_;
    my @cells;
    for my $cell_item ( @{ $table_row_token->matched_items } ) {
        push @cells,
            Cucumber::Messages::TableCell->new(
                location => $self->get_location(
                    $table_row_token, $cell_item->{'column'}
                ),
                value => $cell_item->{'text'}
            );
    }

    return \@cells;
}

sub get_description { return ($_[1]->get_single('Description') || '') }
sub get_steps       { return $_[1]->get_items('Step') }

sub next_id {
    my $self = shift;
    return $self->{'id_generator'}->();
}

## no critic (ProhibitExcessComplexity, ProhibitCascadingIfElse)
sub transform_node {
    my ( $self, $node ) = @_;

    if ( $node->rule_type eq 'Step' ) {
        my $step_line  = $node->get_token('StepLine');
        my $data_table = $node->get_single('DataTable') || undef;
        my $doc_string = $node->get_single('DocString') || undef;

        return Cucumber::Messages::Step->new(
            id           => $self->next_id,
            location     => $self->get_location($step_line),
            keyword      => $step_line->matched_keyword,
            keyword_type => $step_line->matched_keyword_type,
            text         => $step_line->matched_text,
            doc_string   => $doc_string,
            data_table   => $data_table,
            );
    } elsif ( $node->rule_type eq 'DocString' ) {
        my $separator_token = $node->get_tokens('DocStringSeparator')->[0];
        my $media_type      = $separator_token->matched_text;
        my $delimiter       = $separator_token->matched_keyword;
        my $line_tokens     = $node->get_tokens('Other');
        my $content = join( "\n", map { $_->matched_text } @{$line_tokens} );

        return Cucumber::Messages::DocString->new(
            location    => $self->get_location($separator_token),
            content     => $content,
            media_type  => ($media_type eq '' ) ? undef : $media_type,
            delimiter   => $delimiter
            );
    } elsif ( $node->rule_type eq 'DataTable' ) {
        my $rows = $self->get_table_rows($node);
        return Cucumber::Messages::DataTable->new(
            location => $rows->[0]->{'location'},
            rows     => $rows
        );
    } elsif ( $node->rule_type eq 'Background' ) {
        my $background_line = $node->get_token('BackgroundLine');
        my $description     = $self->get_description($node);
        my $steps           = $self->get_steps($node);

        return Cucumber::Messages::Background->new(
            id          => $self->next_id,
            location    => $self->get_location($background_line),
            keyword     => $background_line->matched_keyword,
            name        => $background_line->matched_text,
            description => $description,
            steps       => $steps
            );
    } elsif ( $node->rule_type eq 'ScenarioDefinition' ) {
        my $tags          = $self->get_tags($node);
        my $scenario_node = $node->get_single('Scenario');
        my $scenario_line = $scenario_node->get_token('ScenarioLine');
        my $description   = $self->get_description($scenario_node);
        my $steps         = $self->get_steps($scenario_node);
        my $examples      = $scenario_node->get_items('ExamplesDefinition');

        return Cucumber::Messages::Scenario->new(
            id          => $self->next_id,
            tags        => $tags,
            location    => $self->get_location($scenario_line),
            keyword     => $scenario_line->matched_keyword,
            name        => $scenario_line->matched_text,
            description => $description,
            steps       => $steps,
            examples    => $examples
            );
    } elsif ( $node->rule_type eq 'Rule' ) {
        my $header = $node->get_single('RuleHeader');
        unless ($header) {
            warn "Missing RuleHeader!";
            return;
        }
        my $rule_line = $header->get_token('RuleLine');
        unless ($rule_line) {
            warn "Missing RuleLine";
            return;
        }
        my $tags = $self->get_tags($header);

        my @children;
        my $background = $node->get_single('Background');
        if ( $background ) {
            push @children,
                Cucumber::Messages::RuleChild->new(
                    background => $background
                );
        }
        push @children, (
            map {
                Cucumber::Messages::RuleChild->new(
                    scenario => $_
                    )
            } @{ $node->get_items('ScenarioDefinition') }
            );

        my $description          = $self->get_description($header);

        return Cucumber::Messages::Rule->new(
            id                  => $self->next_id,
            tags                => $tags,
            location            => $self->get_location($rule_line),
            keyword             => $rule_line->matched_keyword,
            name                => $rule_line->matched_text,
            description         => $description,
            children            => \@children
        );
    } elsif ( $node->rule_type eq 'ExamplesDefinition' ) {
        my $examples_node  = $node->get_single('Examples');
        my $examples_line  = $examples_node->get_token('ExamplesLine');
        my $description    = $self->get_description($examples_node);
        my $examples_table = $examples_node->get_single('ExamplesTable');
        my $rows           =
            $examples_table ? $self->get_table_rows($examples_table) : undef;
        my $tags           = $self->get_tags($node);

        return Cucumber::Messages::Examples->new(
            id          => $self->next_id,
            tags        => $tags,
            location    => $self->get_location($examples_line),
            keyword     => $examples_line->matched_keyword,
            name        => $examples_line->matched_text,
            description => $description,
            table_header => ($rows ? shift @{ $rows } : undef),
            table_body   => ($rows ? $rows : [])
        );
    } elsif ( $node->rule_type eq 'Description' ) {
        my @description = @{ $node->get_tokens('Other') };

        # Trim trailing empty lines
        pop @description
          while ( @description && !$description[-1]->matched_text );

        return join "\n", map { $_->matched_text } @description;
    } elsif ( $node->rule_type eq 'Feature' ) {
        my $header = $node->get_single('FeatureHeader');
        unless ($header) {
            warn "Missing FeatureHeader!";
            return;
        }
        my $feature_line = $header->get_token('FeatureLine');
        unless ($feature_line) {
            warn "Missing FeatureLine";
            return;
        }
        my $tags = $self->get_tags($header);

        my @children;
        my $background = $node->get_single('Background');
        if ( $background ) {
            push @children,
                Cucumber::Messages::FeatureChild->new(
                    background => $background
                );
        }
        push @children,
            map {
                Cucumber::Messages::FeatureChild->new(
                    scenario => $_
                    )
            } @{ $node->get_items('ScenarioDefinition') };
        push @children,
            map {
                Cucumber::Messages::FeatureChild->new(
                    rule => $_
                    )
            } @{ $node->get_items('Rule') };

        my $description          = $self->get_description($header);
        my $language             = $feature_line->matched_gherkin_dialect;

        return Cucumber::Messages::Feature->new(
            tags        => $tags,
            location    => $self->get_location($feature_line),
            language    => $language,
            keyword     => $feature_line->matched_keyword,
            name        => $feature_line->matched_text,
            description => $description,
            children    => \@children
            );
    } elsif ( $node->rule_type eq 'GherkinDocument' ) {
         my $feature = $node->get_single('Feature');

         return Cucumber::Messages::Envelope->new(
             gherkin_document => Cucumber::Messages::GherkinDocument->new(
                 uri      => $self->{'uri'},
                 feature  => $feature,
                 comments => $self->{'comments'},
             ));
    } else {
        return $node;
    }
}
## use critic

1;
