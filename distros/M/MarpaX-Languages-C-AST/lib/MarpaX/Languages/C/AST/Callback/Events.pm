use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Callback::Events;
use MarpaX::Languages::C::AST::Util qw/:all/;
use parent qw/MarpaX::Languages::C::AST::Callback/;

# ABSTRACT: Events callback when translating a C source to an AST

use Carp qw/croak/;
use SUPER;
use constant LHS_RESET_EVENT => '<reset>';
use constant LHS_PROCESS_EVENT => '<process>';
use constant CLOSEANYSCOPE_PRIORITY => -1000;
use constant RESETANYDATA_PRIORITY => -2000;

our $VERSION = '0.48'; # VERSION


sub new {
    my ($class, $outerSelf) = @_;

    my $self = $class->SUPER();

    if (! defined($outerSelf) || ref($outerSelf) ne 'MarpaX::Languages::C::AST') {
      croak 'outerSelf must be a reference to MarpaX::Languages::C::AST'
    }

    $self->hscratchpad('_impl', $outerSelf->{_impl});
    $self->hscratchpad('_scope', $outerSelf->{_scope});
    $self->hscratchpad('_sourcep', $outerSelf->{_sourcep});

    # #######################################################################################################################
    # From now on, the technique is always the same:
    #
    # For a rule that will be isolated for convenience (the grammar uses the action => deref if needed) like:
    # LHS ::= RHS1 RHS2 ... RHSn
    #
    # Suppose we want, at <LHS$> to inspect genome data <Gx,y,...> aggregation associated with rule <RHSn>.
    #
    # - We create a brand new callback object:
    # - We make sure LHS rule is unique, creating a proxy rule with action => deref if needed
    # - We make sure <LHS$> completion event exist
    # - We make sure <LHSRHSn$> completion events exist
    # - We make sure <^LHSRHSn> predictions events exist
    # - We create a dedicated callback that is subscribed to every unique <Gx$> and that collect its data
    #
    # - Every <^LHSRHSn> is resetting the data collections they depend upon
    # - Every <LHSRHSn$> is copying the data collections they depend upon and reset it
    # - The first LHSRHS has a special behaviour: if <LHSRHS$> is hitted while there is a pending <LHS$>,
    #   this mean that we are recursively hitting the rule. This will push one level. Levels are popped off at <LHS$>.
    #
    # - We create callbacks to <Gx$> that are firing the inner callback object.
    #
    # - For these callbacks we want to know if the scopes must be all closed before doing the processing.
    #   This is true in general except for functionDefinitionCheck1 and functionDefinitionCheck2 where we want to
    #   access the declarationList at scope 1 and the declarationSpecifiers at scope 0.
    #
    # #######################################################################################################################

    # ################################################################################################
    # A directDeclarator introduces a typedef-name only when it eventually participates in the grammar
    # rule:
    # declaration ::= declarationSpecifiers initDeclaratorList SEMICOLON
    #
    # Isolated to single rule:
    #
    # declarationCheck ::= declarationCheckdeclarationSpecifiers declarationCheckinitDeclaratorList SEMICOLON
    # #######################################################################################################################
    my @callbacks = ();
    push(@callbacks,
         $self->_register_rule_callbacks({
                                          lhs => 'declarationCheck',
                                          rhs => [ [ 'declarationCheckdeclarationSpecifiers', [ [ 'storageClassSpecifierTypedef', 'typedef' ] ] ],
                                                   [ 'declarationCheckinitDeclaratorList',    [ [ 'directDeclaratorIdentifier', sub { $outerSelf->{_lastIdentifier} } ] ] ]
                                                 ],
                                          method => \&_declarationCheck,
                                          # ---------------------------
                                          # directDeclarator constraint
                                          # ---------------------------
                                          # In:
                                          # structDeclarator ::= declarator COLON constantExpression | declarator
                                          #
                                          # ordinary name space names cannot be defined. Therefore all parse symbol activity must be
                                          # suspended for structDeclarator.
                                          #
                                          # structDeclarator$ will be hitted many time (right recursive), but its container
                                          # structDeclaration will be hitted only once.
                                          # ---------------------------
                                          counters => {
                                                       'structContext' => [ 'structContextStart[]', 'structContextEnd[]', 'level' ]
                                                      },
                                          process_priority => CLOSEANYSCOPE_PRIORITY - 1
                                         }
                                        )
        );


    # ------------------------------------------------------------------------------------------
    # directDeclarator constraint
    # ------------------------------------------------------------------------------------------
    # In:
    # functionDefinition ::= declarationSpecifiers declarator declarationList? compoundStatement
    # typedef is syntactically allowed but never valid in either declarationSpecifiers or
    # declarationList.
    #
    # Isolated to two rules:
    #
    # functionDefinitionCheck1 ::= functionDefinitionCheck1declarationSpecifiers declarator
    #                              functionDefinitionCheck1declarationList
    #                              compoundStatementReenterScope
    # functionDefinitionCheck2 ::= functionDefinitionCheck2declarationSpecifiers declarator
    #                              compoundStatementReenterScope
    #
    # Note: We want the processing to happen before the scopes are really closed.
    # ------------------------------------------------------------------------------------------
    push(@callbacks,
         $self->_register_rule_callbacks({
                                          lhs => 'functionDefinitionCheck1',
                                          rhs => [ [ 'functionDefinitionCheck1declarationSpecifiers', [ [ 'storageClassSpecifierTypedef', 'typedef' ] ] ],
                                                   [ 'functionDefinitionCheck1declarationList',       [ [ 'storageClassSpecifierTypedef', 'typedef' ] ] ]
                                                 ],
                                          method => \&_functionDefinitionCheck1,
                                          process_priority => CLOSEANYSCOPE_PRIORITY + 1
                                         }
                                        )
        );
    push(@callbacks,
         $self->_register_rule_callbacks({
                                          lhs => 'functionDefinitionCheck2',
                                          rhs => [ [ 'functionDefinitionCheck2declarationSpecifiers', [ [ 'storageClassSpecifierTypedef', 'typedef' ] ] ],
                                                 ],
                                          method => \&_functionDefinitionCheck2,
                                          process_priority => CLOSEANYSCOPE_PRIORITY + 1
                                         }
                                        )
        );

    # ------------------------------------------------------------------------------------------
    # directDeclarator constraint
    # ------------------------------------------------------------------------------------------
    # In:
    # parameterDeclaration ::= declarationSpecifiers declarator
    # typedef is syntactically allowed but never valid, but can be obscured by a local parameter.
    #
    # Isolated to:
    #
    # parameterDeclarationCheck ::= declarationSpecifiers declarator
    # ------------------------------------------------------------------------------------------
    push(@callbacks,
         $self->_register_rule_callbacks({
                                          lhs => 'parameterDeclarationCheck',
                                          rhs => [ [ 'parameterDeclarationdeclarationSpecifiers', [ [ 'storageClassSpecifierTypedef', 'typedef' ] ] ],
                                                   [ 'parameterDeclarationCheckDeclarator',       [ [ 'directDeclaratorIdentifier', sub { $outerSelf->{_lastIdentifier} } ] ] ]
                                                 ],
                                          counters => {
                                                       'structContext' => [ 'structContextStart[]', 'structContextEnd[]', 'level' ]
                                                      },
                                          method => \&_parameterDeclarationCheck
                                         }
                                        )
        );
    # ################################################################################################
    # An enumerationConstantIdentifier introduces a enum-name. Full point.
    # rule:
    # enumerationConstantIdentifier ::= IDENTIFIER
    # ################################################################################################
    $self->register(MarpaX::Languages::C::AST::Callback::Method->new
                    (
                     description => 'enumerationConstantIdentifier$',
                     method =>  [ \&_enumerationConstantIdentifier_optimized, $outerSelf->{_impl}, $outerSelf->{_scope} ],
                     option => MarpaX::Languages::C::AST::Callback::Option->new
                     (
                      condition => [ [ 'auto' ] ]
                     )
                    )
        );

    # #############################################################################################
    # Register scope callbacks
    # #############################################################################################
    $self->hscratchpad('_scope')->parseEnterScopeCallback(\&_enterScopeCallback, $self, @callbacks);
    $self->hscratchpad('_scope')->parseExitScopeCallback(\&_exitScopeCallback, $self, @callbacks);
    #
    # and the detection of filescope declarator
    #
    $self->register(MarpaX::Languages::C::AST::Callback::Method->new
                    (
                     description => 'fileScopeDeclarator$',
                     method => [ \&_set_helper_optimized, 'fileScopeDeclarator', 1, 'reenterScope', 0 ],
                     method_void => 1,
                     option => MarpaX::Languages::C::AST::Callback::Option->new
                     (
                      condition => [
                                    [ 'auto' ],
                                    [ sub { my ($method, $callback, $eventsp, $scope) = @_;
                                            return ($scope->parseScopeLevel == 0);
                                          },
                                      $self->hscratchpad('_scope')
                                    ]
                                   ],
                      topic => {'fileScopeDeclarator' => 1,
                                'reenterScope' => 1},
                      topic_persistence => 'any'
                     )
                    )
        );
    #
    # ^externalDeclaration will always close any remaining scope and reset all data
    #
    $self->register(MarpaX::Languages::C::AST::Callback::Method->new
                    (
                     description => '^externalDeclaration',
                     method => [ \&_closeAnyScope, $self->hscratchpad('_scope') ],
                     option => MarpaX::Languages::C::AST::Callback::Option->new
                     (
                      condition => [ [ 'auto' ] ],
                      priority => CLOSEANYSCOPE_PRIORITY
                     )
                    )
        );
    $self->register(MarpaX::Languages::C::AST::Callback::Method->new
                    (
                     description => '^externalDeclaration',
                     method => [ \&_resetAnyData, @callbacks ],
                     option => MarpaX::Languages::C::AST::Callback::Option->new
                     (
                      condition => [ [ 'auto' ] ],
                      priority => RESETANYDATA_PRIORITY
                     )
                    )
        );

    #
    # We are not going to register/unregister/unsubscribe/change topics etc... we can say to Callback that it can
    # can cache everything that is intensive. Take care, any configuration data to Callback becomes then static.
    #
    foreach ($self, @callbacks) {
      $_->cache()
    }

    return $self
}
# ----------------------------------------------------------------------------------------
sub _closeAnyScope {
    my ($method, $callback, $eventsp, $scope) = @_;

    while ($scope->parseScopeLevel >= 1) {
      $scope->doExitScope()
    }
}
# ----------------------------------------------------------------------------------------
sub _resetAnyData {
    my ($method, $callback, $eventsp, @callbacks) = @_;

    foreach (@callbacks) {
      $_->exec(LHS_RESET_EVENT)
    }
}
# ----------------------------------------------------------------------------------------
sub _enumerationConstantIdentifier {
    my ($method, $callback, $eventsp) = @_;

    my $impl = $callback->hscratchpad('_impl');

    my $enum = lastCompleted($impl, 'enumerationConstantIdentifier');
    return $callback->hscratchpad('_scope')->parseEnterEnum($enum, startAndLength($impl))
}
sub _enumerationConstantIdentifier_optimized {
    # my ($method, $callback, $eventsp, $impl, $scope) = @_;

    return $_[4]->parseEnterEnum(lastCompleted($_[3], 'enumerationConstantIdentifier'), startAndLength($_[3]))
}
# ----------------------------------------------------------------------------------------
sub _parameterDeclarationCheck {
    my ($method, $callback, $eventsp) = @_;
    #
    # Get the topics data we are interested in
    #
    my $parameterDeclarationdeclarationSpecifiers = $callback->topic_level_fired_data('parameterDeclarationdeclarationSpecifiers$');
    my $parameterDeclarationCheckDeclarator = $callback->topic_fired_data('parameterDeclarationCheckDeclarator$');

    #
    # By definition parameterDeclarationdeclarationSpecifiers contains only typedefs
    #
    my $nbTypedef = $#{$parameterDeclarationdeclarationSpecifiers};
    if ($nbTypedef >= 0) {
        my ($start_lengthp, $line_columnp, $last_completed)  = @{$parameterDeclarationdeclarationSpecifiers->[0]};
        logCroak("[%s[%d]] %s is not valid in a parameter declaration\n%s\n", whoami(__PACKAGE__), $callback->currentTopicLevel, $last_completed, showLineAndCol(@{$line_columnp}, $callback->hscratchpad('_sourcep')))
    }
    #
    # By definition parameterDeclarationCheckDeclarator contains only directDeclaratorIdentifier
    #
    _enterOrObscureTypedef($callback, $nbTypedef, $parameterDeclarationCheckDeclarator);
    #
    # We are called at every parameterDeclarationCheck, and parameterDeclarationCheckDeclarator is an aggregation
    # of all directDeclaratorIdentifier. We don't need this data anymore
    #
    return $callback->reset_topic_fired_data('parameterDeclarationCheckDeclarator$')
}
# ----------------------------------------------------------------------------------------
sub _functionDefinitionCheck1 {
    my ($method, $callback, $eventsp) = @_;
    #
    # Get the topics data we are interested in
    #
    my $functionDefinitionCheck1declarationSpecifiers = $callback->topic_level_fired_data('functionDefinitionCheck1declarationSpecifiers$', -1);
    my $functionDefinitionCheck1declarationList = $callback->topic_fired_data('functionDefinitionCheck1declarationList$');

    #
    # By definition functionDefinitionCheck1declarationSpecifiers contains only typedefs
    # By definition functionDefinitionCheck1declarationList contains only typedefs
    #
    my $nbTypedef1 = $#{$functionDefinitionCheck1declarationSpecifiers};
    if ($nbTypedef1 >= 0) {
        my ($start_lengthp, $line_columnp, $last_completed)  = @{$functionDefinitionCheck1declarationSpecifiers->[0]};
        logCroak("[%s[%d]] %s is not valid in a function declaration specifier\n%s\n", whoami(__PACKAGE__), $callback->currentTopicLevel, $last_completed, showLineAndCol(@{$line_columnp}, $callback->hscratchpad('_sourcep')))
    }

    my $nbTypedef2 = $#{$functionDefinitionCheck1declarationList};
    if ($nbTypedef2 >= 0) {
        my ($start_lengthp, $line_columnp, $last_completed)  = @{$functionDefinitionCheck1declarationList->[0]};
        logCroak("[%s[%d]] %s is not valid in a function declaration list\n%s\n", whoami(__PACKAGE__), $callback->currentTopicLevel, $last_completed, showLineAndCol(@{$line_columnp}, $callback->hscratchpad('_sourcep')))
    }
}
sub _functionDefinitionCheck2 {
    my ($method, $callback, $eventsp) = @_;
    #
    # Get the topics data we are interested in
    #
    my $functionDefinitionCheck2declarationSpecifiers = $callback->topic_level_fired_data('functionDefinitionCheck2declarationSpecifiers$', -1);

    #
    # By definition functionDefinitionCheck2declarationSpecifiers contains only typedefs
    #
    my $nbTypedef = $#{$functionDefinitionCheck2declarationSpecifiers};
    if ($nbTypedef >= 0) {
        my ($start_lengthp, $line_columnp, $last_completed)  = @{$functionDefinitionCheck2declarationSpecifiers->[0]};
        logCroak("[%s[%d]] %s is not valid in a function declaration specifier\n%s\n", whoami(__PACKAGE__), $callback->currentTopicLevel, $last_completed, showLineAndCol(@{$line_columnp}, $callback->hscratchpad('_sourcep')))
    }
}
# ----------------------------------------------------------------------------------------
sub _declarationCheck {
    my ($method, $callback, $eventsp) = @_;

    #
    # Get the topics data we are interested in
    #
    my $declarationCheckdeclarationSpecifiers = $callback->topic_fired_data('declarationCheckdeclarationSpecifiers$');
    my $declarationCheckinitDeclaratorList = $callback->topic_fired_data('declarationCheckinitDeclaratorList$');

    #
    # By definition declarationCheckdeclarationSpecifiers contains only typedefs
    # By definition declarationCheckinitDeclaratorList contains only directDeclaratorIdentifier
    #

    my $nbTypedef = $#{$declarationCheckdeclarationSpecifiers};
    if ($nbTypedef > 0) {
        #
        # Take the second typedef
        #
        my ($start_lengthp, $line_columnp, $last_completed)  = @{$declarationCheckdeclarationSpecifiers->[1]};
        logCroak("[%s[%d]] %s cannot appear more than once\n%s\n", whoami(__PACKAGE__), $callback->currentTopicLevel, $last_completed, showLineAndCol(@{$line_columnp}, $callback->hscratchpad('_sourcep')))
    }

    return _enterOrObscureTypedef($callback, $nbTypedef, $declarationCheckinitDeclaratorList)
}
# ----------------------------------------------------------------------------------------
sub _enterOrObscureTypedef {
  my ($callback, $nbTypedef, $directDeclaratorIdentifierArrayp) = @_;

  my $scope = $callback->hscratchpad('_scope');

  foreach (@{$directDeclaratorIdentifierArrayp}) {
    my ($start_lengthp, $line_columnp, $last_completed, %counters)  = @{$_};
    if (! $counters{structContext}) {
      if ($nbTypedef >= 0) {
        $scope->parseEnterTypedef($last_completed, $start_lengthp)
      } else {
        $scope->parseObscureTypedef($last_completed)
      }
    }
  }
}
# ----------------------------------------------------------------------------------------
sub _enterScopeCallback {
    foreach (@_) {
        $_->pushTopicLevel()
    }
}
sub _exitScopeCallback {
    foreach (@_) {
        $_->popTopicLevel()
    }
}
# ----------------------------------------------------------------------------------------
sub _storage_helper {
    my ($method, $callback, $eventsp, $event, $countersHashp, $fixedValue, $callbackValue, $impl) = @_;
    #
    # Collect the counters
    #
    my %counters = ();
    foreach (keys %{$countersHashp}) {
      my $counterDatap = $callback->topic_fired_data($_) || [0];
      $counters{$_} = $counterDatap->[0] || 0
    }
    #
    # The event name, by convention, is 'event$' or '^$event'
    #
    my $rc;

    my $g1 = $impl->current_g1_location();
    my ($start, $length) = $impl->g1_location_to_span($g1);
    if (substr($event, 0, 1) eq '^') {
        $rc = [ [ $start, $length ], lineAndCol($impl, $g1, $start), %counters ]
    } elsif (substr($event, -1, 1) eq '$') {
        if (defined($callbackValue)) {
          $rc = [ [ $start, $length ], lineAndCol($impl, $g1, $start), &$callbackValue(), %counters ]
        } else {
          substr($event, -1, 1, '');
          $rc = [ [ $start, $length ], lineAndCol($impl, $g1, $start), $fixedValue || lastCompleted($impl, $event), %counters ]
        }
    }

    return $rc
}
sub _storage_helper_optimized {
    my ($method, $callback, $eventsp, $event, $countersHashp, $fixedValue, $callbackValue, $impl) = @_;
    #
    # Collect the counters
    #
    my %counters = ();
    foreach (keys %{$countersHashp}) {
      my $counterDatap = $callback->topic_fired_data($_) || [0];
      $counters{$_} = $counterDatap->[0] || 0
    }
    #
    # The event name, by convention, is 'event$' or '^$event'
    #
    my $rc;

    my $g1 = $_[7]->current_g1_location();
    my ($start, $length) = $_[7]->g1_location_to_span($g1);

    if (substr($event, 0, 1) eq '^') {
        $rc = [ [ $start, $length ], lineAndCol($_[7], $g1, $start), %counters ]
    } elsif (substr($event, -1, 1) eq '$') {
        if (defined($callbackValue)) {
          $rc = [ [ $start, $length ], lineAndCol($_[7], $g1, $start), &$callbackValue(), %counters ]
        } else {
          substr($event, -1, 1, '');
          $rc = [ [ $start, $length ], lineAndCol($_[7], $g1, $start), $_[5] || lastCompleted($_[7], $event), %counters ]
        }
    }

    return $rc
}
# ----------------------------------------------------------------------------------------
sub _inc_helper {
    my ($method, $callback, $eventsp, $topic, $increment) = @_;

    my $old_value = $callback->topic_fired_data($topic)->[0] || 0;
    my $new_value = $old_value + $increment;

    return $new_value
}
sub _inc_helper_optimized {
    # my ($method, $callback, $eventsp, $topic, $increment) = @_;

    return (($_[1]->topic_fired_data($_[3])->[0] || 0) + $_[4])
}
# ----------------------------------------------------------------------------------------
sub _set_helper {
    my ($method, $callback, $eventsp, %topic) = @_;

    foreach (keys %topic) {
      $callback->topic_fired_data($_, [ $topic{$_} ])
    }
}
sub _set_helper_optimized {
    my (undef, undef, undef, %topic) = @_;

    foreach (keys %topic) {
      $_[1]->topic_fired_data($_, [ $topic{$_} ])
    }
}
# ----------------------------------------------------------------------------------------
sub _reset_helper {
    my ($method, $callback, $eventsp, @topics) = @_;

    my @rc = ();
    return @rc
}
sub _reset_helper_optimized {
    return ()
}
# ----------------------------------------------------------------------------------------
sub _collect_and_reset_helper {
    my ($method, $callback, $eventsp, @topics) = @_;

    my @rc = ();
    foreach (@topics) {
        my $topic = $_;
        push(@rc, @{$callback->topic_fired_data($topic)});
        $callback->topic_fired_data($topic, [])
    }

    return @rc
}
sub _collect_and_reset_helper_optimized {
    #
    # This routine is called very often, I tried top optimize it
    #
    # my ($method, $callback, $eventsp, @topics) = @_;

    map {
        my $this = $_[1]->topic_fired_data($_);
        $_[1]->topic_fired_data($_, []);
        @{$this};
    } @_[3..$#_]

}
# ----------------------------------------------------------------------------------------
sub _subFire {
  my ($method, $callback, $eventsp, $lhs, $subCallback, $filterEventsp, $transformEventsp) = @_;

  my @subEvents = grep {exists($filterEventsp->{$_})} @{$eventsp};
  if (@subEvents) {
    if (defined($transformEventsp)) {
      my %tmp = ();
      my @transformEvents = grep {++$tmp{$_} == 1} map {$transformEventsp->{$_} || $_} @subEvents;
      $subCallback->exec(@transformEvents)
    } else {
      $subCallback->exec(@subEvents)
    }
  }
}
sub _subFire_optimized {
    #
    # This routine is called very often, I tried top optimize it
    #
    # my ($method, $callback, $eventsp, $lhs, $subCallback, $filterEventsp, $transformEventsp) = @_;

  my @subEvents = grep {exists($_[5]->{$_})} @{$_[2]};
  if (@subEvents) {
    if (defined($_[6])) {
      my %tmp = ();
      $_[4]->exec(grep {++$tmp{$_} == 1} map {$_[6]->{$_} || $_} @subEvents)
    } else {
      $_[4]->exec(@subEvents)
    }
  }
}
# ----------------------------------------------------------------------------------------
sub _register_rule_callbacks {
  my ($self, $hashp) = @_;

  #
  # Create inner callback object
  #
  my $callback = MarpaX::Languages::C::AST::Callback->new(log_prefix => '  ' . $hashp->{lhs} . ' ');
  #
  # Propagate internal variables to all callback instances
  #
  $callback->hscratchpad('_impl', $self->hscratchpad('_impl'));
  $callback->hscratchpad('_scope', $self->hscratchpad('_scope'));
  $callback->hscratchpad('_sourcep', $self->hscratchpad('_sourcep'));

  #
  # rshProcessEvents will be the list of processing events that we forward to the inner callback object
  #
  my %rshProcessEvents = ();
  #
  # Counters are events associated to a counter: every ^xxx increases a counter.
  # Every xxx$ is decreasing it.
  # To any genome data, we have attached a hash like {counter1 => counter1_value, counter2 => etc...}
  #
  my $countersHashp = $hashp->{counters} || {};
  foreach (keys %{$countersHashp}) {
    my $counter = $_;
    my ($eventStart, $eventEnd, $persistence) = @{$countersHashp->{$counter}};
    $persistence ||= 'any';
    ++$rshProcessEvents{$eventStart};
    $callback->register(MarpaX::Languages::C::AST::Callback::Method->new
                        (
                         description => $eventStart,
                         extra_description => $counter . ' [Start] ',
                         method =>  [ \&_inc_helper_optimized, $counter, 1 ],
                         method_mode => 'replace',
                         option => MarpaX::Languages::C::AST::Callback::Option->new
                         (
                          topic => {$counter => 1},
                          topic_persistence => $persistence,
                          condition => [ [ 'auto' ] ],  # == match on description
                          priority => 999
                         )
                        )
                       );
    ++$rshProcessEvents{$eventEnd};
    $callback->register(MarpaX::Languages::C::AST::Callback::Method->new
                        (
                         description => $eventEnd,
                         extra_description => $counter . ' [End] ',
                         method =>  [ \&_inc_helper_optimized, $counter, -1 ],
                         method_mode => 'replace',
                         option => MarpaX::Languages::C::AST::Callback::Option->new
                         (
                          topic => {$counter => 1},
                          topic_persistence => $persistence,
                          condition => [ [ 'auto' ] ],  # == match on description
                          priority => 999
                         )
                        )
                       );
  }

  #
  # Collect the unique list of <Gx$>
  #
  my %genomeEvents = ();
  my %genomeEventValues = ();
  foreach (@{$hashp->{rhs}}) {
    my ($rhs, $genomep) = @{$_};
    foreach (@{$genomep}) {
      #
      # The genome events will call, by default, last_completed(), which cost
      # quite a lot. There is no need to do such call when we know in advance
      # what will be to token value.
      my ($name, $value);
      if (ref($_) eq 'ARRAY') {
        #
        # Token value known in advance
        #
        ($name, $value) = @{$_}
      } else {
        ($name, $value) = ($_, undef)
      }
      my $event = $name . '$';
      ++$genomeEvents{$event};
      ++$rshProcessEvents{$event};
      $genomeEventValues{$event} = $value
    }
  }
  #
  # Create data Gx$ data collectors. The data will be collected in a
  # topic with the same name: Gx
  #
  foreach (keys %genomeEvents) {
        my ($fixedValue, $callbackValue) = (undef, undef);
        if (ref($genomeEventValues{$_}) eq 'CODE') {
          $callbackValue = $genomeEventValues{$_}
        } else {
          $fixedValue = $genomeEventValues{$_}
        }
        $callback->register(MarpaX::Languages::C::AST::Callback::Method->new
                            (
                             description => $_,
                             extra_description => "$_ [storage] ",
                             method =>  [ \&_storage_helper_optimized, $_, $countersHashp, $fixedValue, $callbackValue, $self->hscratchpad('_impl') ],
                             option => MarpaX::Languages::C::AST::Callback::Option->new
                             (
                              topic => {$_ => 1},
                              topic_persistence => 'level',
                              condition => [ [ 'auto' ] ],  # == match on description
                              priority => 999
                             )
                            )
            );
  }

  my $i = 0;
  my %rhsTopicsToUpdate = ();
  my %rhsTopicsNotToUpdate = ();
  foreach (@{$hashp->{rhs}}) {
    my ($rhs, $genomep) = @{$_};
    my $rhsTopic = $rhs . '$';
    $rhsTopicsToUpdate{$rhsTopic} = 1;
    $rhsTopicsNotToUpdate{$rhsTopic} = -1;

    my %genomeTopicsToUpdate = ();
    my %genomeTopicsNotToUpdate = ();
    foreach (@{$genomep}) {
      my ($name, $value);
      if (ref($_) eq 'ARRAY') {
        #
        # Token value known in advance
        #
        ($name, $value) = @{$_}
      } else {
        ($name, $value) = ($_, undef)
      }
      $genomeTopicsToUpdate{$name . '$'} = 1;
      $genomeTopicsNotToUpdate{$name . '$'} = -1
    }
    #
    # rhs$ event will collect into rhs$ topic all Gx$ topics (created automatically if needed)
    # and reset them
    #
    my $event = $rhs . '$';
    ++$rshProcessEvents{$event};
    $callback->register(MarpaX::Languages::C::AST::Callback::Method->new
                        (
                         description => $event,
                         extra_description => "$event [process] ",
                         method =>  [ \&_collect_and_reset_helper_optimized, keys %genomeTopicsNotToUpdate ],
                         method_mode => 'push',
                         option => MarpaX::Languages::C::AST::Callback::Option->new
                         (
                          condition => [ [ 'auto' ] ],  # == match on description
                          topic => {$rhsTopic => 1,
                                   %genomeTopicsNotToUpdate},
                          topic_persistence => 'level',
                          priority => 1
                         )
                        )
        );
  }

  #
  # Final callback: this will process the event
  #
  my $lhsProcessEvent = LHS_PROCESS_EVENT;
  my %lhsProcessEvents = ($hashp->{lhs} . '$' => 1);
  my $lhsResetEvent = LHS_RESET_EVENT;
  my %lhsResetEvents = ($hashp->{lhs} . '$' => 1, 'translationUnit$' => 1);
  $callback->register(MarpaX::Languages::C::AST::Callback::Method->new
                  (
                   description => $lhsProcessEvent,
                   method => [ $hashp->{method} ],
                   option => MarpaX::Languages::C::AST::Callback::Option->new
                   (
                    condition => [ [ 'auto' ] ],  # == match on description
                    topic => \%rhsTopicsNotToUpdate,
                    topic_persistence => 'level',
                    priority => 1
                   )
                  )
                 );
  #
  # ... and reset rhs topic data
  #
  $callback->register(MarpaX::Languages::C::AST::Callback::Method->new
                  (
                   description => $lhsResetEvent,
                   method =>  [ \&_reset_helper_optimized, keys %rhsTopicsToUpdate ],
                   method_mode => 'replace',
                   option => MarpaX::Languages::C::AST::Callback::Option->new
                   (
                    condition => [ [ 'auto' ] ],  # == match on description
                    topic => \%rhsTopicsToUpdate,
                    topic_persistence => 'level',
                    priority => 0
                   )
                  )
                 );

  #
  ## Sub-fire RHS processing events for this sub-callback object, except the <LHS$>
  ## that is done just after.
  #
  $self->register(MarpaX::Languages::C::AST::Callback::Method->new
                  (
                   description => $hashp->{lhs} . ' [intermediary events]',
                   method => [ \&_subFire_optimized, $hashp->{lhs}, $callback, \%rshProcessEvents ],
                   option => MarpaX::Languages::C::AST::Callback::Option->new
                   (
                    condition => [
                                  [ sub { return grep {exists($rshProcessEvents{$_})} @{$_[2]} }
                                  ]
                                 ]
                   )
                  )
                 );

  #
  ## For <LHS$> we distinguish the processing event and the reset event.
  ## Processing event can happen at a pre-defined priority because sometimes we
  ## want to fire the <LHS$> processing before a scope is closed.
  ## On the other hand, the reset will always happen after all scopes are
  ## closed.
  #
  $self->register(MarpaX::Languages::C::AST::Callback::Method->new
                  (
                   description => $lhsProcessEvent,
                   method => [ \&_subFire_optimized, $hashp->{lhs}, $callback, \%lhsProcessEvents, {$hashp->{lhs} . '$' => $lhsProcessEvent} ],
                   option => MarpaX::Languages::C::AST::Callback::Option->new
                   (
                    condition => [
                                  [ sub { return grep {exists($lhsProcessEvents{$_})} @{$_[2]} }
                                  ]
                                 ],
                    priority => $hashp->{process_priority} || 0
                   )
                  )
                 );

  return $callback
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Callback::Events - Events callback when translating a C source to an AST

=head1 VERSION

version 0.48

=head1 DESCRIPTION

This modules implements the Marpa events callback using the very simple framework MarpaX::Languages::C::AST::Callback. It is useful because it shows the FUNCTIONAL things that appear within the events: monitor the TYPEDEFs, introduce/obscure names in name space, apply the few grammar constraints needed at parsing time, etc.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
