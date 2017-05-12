#!/usr/bin/perl -w
use strict;

use Test::More;
use Test::Differences;
use Test::Exception;
use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::CallTree");
use_ok("Devel::PerlySense::CallTree::Graph");



my $source = "
#     Devel::PerlySense->oLocationSmartGoTo
#     Devel::PerlySense->oLocationSmartDoc
#     Devel::PerlySense->classByName
#         * Devel::PerlySense->oLocationSmartGoTo
#         * Devel::PerlySense->oLocationSmartDoc
#     Devel::PerlySense->aDocumentFindModuleWithInterface
#             Devel::PerlySense::Class->new
#         Devel::PerlySense::Class->findBaseClasses
#     Devel::PerlySense::Class->newFromName
#         * Devel::PerlySense->oLocationSmartGoTo
#             Devel::PerlySense::Class->oLocationMethodGoTo
#         Devel::PerlySense->oLocationMethodDefinitionFromDocument
#         * Devel::PerlySense::Document->oLocationSubDefinition
#     Devel::PerlySense::Document->oLocationSubDefinition
#             * Devel::PerlySense->oLocationSmartDoc
#             Devel::PerlySense::Class->oLocationMethodDoc
#             Devel::PerlySense::Document::Api::Method->new
#         Devel::PerlySense->oLocationMethodDocFromDocument
#         * Devel::PerlySense::Document->oLocationSubDefinition
#         * Devel::PerlySense::Document->oLocationPod
#     Devel::PerlySense::Document->oLocationPod
#             * Devel::PerlySense->aDocumentFindModuleWithInterface
#             Devel::PerlySense->aApiOfClass
#             * Devel::PerlySense::Document->determineLikelyApi0
#             Devel::PerlySense::Editor->textClassApi
#         Devel::PerlySense::Document->determineLikelyApi
#     Devel::PerlySense::Document->determineLikelyApi0
# Devel::PerlySense->oDocumentFindModule
";

ok(my $call_tree = Devel::PerlySense::CallTree->new(source => $source), "new ok");

eq_or_diff(
    [ map { $_->id } @{$call_tree->callers} ],
    [
        "devel_perlysense__odocumentfindmodule",
        "devel_perlysense_document__determinelikelyapi0",
        "devel_perlysense_document__determinelikelyapi",
        "devel_perlysense_editor__textclassapi",
        "devel_perlysense_document__determinelikelyapi0",
        "devel_perlysense__aapiofclass",
        "devel_perlysense__adocumentfindmodulewithinterface",
        "devel_perlysense_document__olocationpod",
        "devel_perlysense_document__olocationpod",
        "devel_perlysense_document__olocationsubdefinition",
        "devel_perlysense__olocationmethoddocfromdocument",
        "devel_perlysense_document_api_method__new",
        "devel_perlysense_class__olocationmethoddoc",
        "devel_perlysense__olocationsmartdoc",
        "devel_perlysense_document__olocationsubdefinition",
        "devel_perlysense_document__olocationsubdefinition",
        "devel_perlysense__olocationmethoddefinitionfromdocument",
        "devel_perlysense_class__olocationmethodgoto",
        "devel_perlysense__olocationsmartgoto",
        "devel_perlysense_class__newfromname",
        "devel_perlysense_class__findbaseclasses",
        "devel_perlysense_class__new",
        "devel_perlysense__adocumentfindmodulewithinterface",
        "devel_perlysense__olocationsmartdoc",
        "devel_perlysense__olocationsmartgoto",
        "devel_perlysense__classbyname",
        "devel_perlysense__olocationsmartdoc",
        "devel_perlysense__olocationsmartgoto",
    ],
    "Correctly parsed ids",
);

eq_or_diff(
    $call_tree->method_called_by_caller,
    #   Target <-- Caller
    {
        "Devel::PerlySense::Document->oLocationPod" => {
            "Devel::PerlySense::Document->oLocationSubDefinition" => 1,
            "Devel::PerlySense::Document->oLocationPod" => 1,
            "Devel::PerlySense->oLocationMethodDocFromDocument" => 1
        },
        "Devel::PerlySense->aDocumentFindModuleWithInterface" => {
            "Devel::PerlySense->oLocationSmartGoTo" => 1,
            "Devel::PerlySense->oLocationSmartDoc" => 1
        },
        "Devel::PerlySense::Document->determineLikelyApi" => {
            "Devel::PerlySense::Document->determineLikelyApi0" => 1,
            "Devel::PerlySense->aApiOfClass" => 1,
            "Devel::PerlySense->aDocumentFindModuleWithInterface" => 1,
            "Devel::PerlySense::Editor->textClassApi" => 1
        },
        "Devel::PerlySense::Document->oLocationSubDefinition" => {
            "Devel::PerlySense->oLocationSmartGoTo" => 1,
            "Devel::PerlySense::Document->oLocationSubDefinition" => 1,
            "Devel::PerlySense->oLocationMethodDefinitionFromDocument" => 1
        },
        "Devel::PerlySense::Class->newFromName" => {
            "Devel::PerlySense::Class->findBaseClasses" => 1
        },
        "Devel::PerlySense->oLocationMethodDefinitionFromDocument" => {
            "Devel::PerlySense::Class->oLocationMethodGoTo" => 1
        },
        "Devel::PerlySense->oLocationMethodDocFromDocument" => {
            "Devel::PerlySense::Class->oLocationMethodDoc" => 1,
            "Devel::PerlySense->oLocationSmartDoc" => 1,
            "Devel::PerlySense::Document::Api::Method->new" => 1
        },
        "Devel::PerlySense->oDocumentFindModule" => {
            "Devel::PerlySense::Document->determineLikelyApi0" => 1,
            "Devel::PerlySense::Document->oLocationSubDefinition" => 1,
            "Devel::PerlySense::Class->newFromName" => 1,
            "Devel::PerlySense->oLocationSmartGoTo" => 1,
            "Devel::PerlySense->oLocationSmartDoc" => 1,
            "Devel::PerlySense->aDocumentFindModuleWithInterface" => 1,
            "Devel::PerlySense->classByName" => 1,
            "Devel::PerlySense::Document->oLocationPod" => 1
        },
        "Devel::PerlySense::Class->findBaseClasses" => {
            "Devel::PerlySense::Class->new" => 1
        },
        "Devel::PerlySense::Document->determineLikelyApi0" => {
            "Devel::PerlySense::Document->determineLikelyApi" => 1
        }
    },
    "Call tree ok",
);


use Devel::PerlySense::CallTree::Graph;
subtest create_graph => sub {
    my $call_tree = Devel::PerlySense::CallTree->new(source => $source);
    my $graph = Devel::PerlySense::CallTree::Graph->new({
        call_tree => $call_tree,
    });
    lives_ok(
        sub { $graph->create_graph() },
        "create_graph ok",
    );
};


done_testing();

__END__

# Devel::PerlySense->oDocumentFindModule
#     Devel::PerlySense::Document->determineLikelyApi0
#         Devel::PerlySense::Document->determineLikelyApi
#             Devel::PerlySense::Editor->textClassApi
#             * Devel::PerlySense::Document->determineLikelyApi0
#             Devel::PerlySense->aApiOfClass
#             * Devel::PerlySense->aDocumentFindModuleWithInterface
#     Devel::PerlySense::Document->oLocationPod
#         * Devel::PerlySense::Document->oLocationPod
#         * Devel::PerlySense::Document->oLocationSubDefinition
#         Devel::PerlySense->oLocationMethodDocFromDocument
#             Devel::PerlySense::Document::Api::Method->new
#             Devel::PerlySense::Class->oLocationMethodDoc
#             * Devel::PerlySense->oLocationSmartDoc
#     Devel::PerlySense::Document->oLocationSubDefinition
#         * Devel::PerlySense::Document->oLocationSubDefinition
#         Devel::PerlySense->oLocationMethodDefinitionFromDocument
#             Devel::PerlySense::Class->oLocationMethodGoTo
#         * Devel::PerlySense->oLocationSmartGoTo
#     Devel::PerlySense::Class->newFromName
#         Devel::PerlySense::Class->findBaseClasses
#             Devel::PerlySense::Class->new
#     Devel::PerlySense->aDocumentFindModuleWithInterface
#         * Devel::PerlySense->oLocationSmartDoc
#         * Devel::PerlySense->oLocationSmartGoTo
#     Devel::PerlySense->classByName
#     Devel::PerlySense->oLocationSmartDoc
#     Devel::PerlySense->oLocationSmartGoTo
