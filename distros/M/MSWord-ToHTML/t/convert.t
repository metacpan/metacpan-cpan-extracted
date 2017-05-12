#!/usr/bin/env perl

use strictures 1;
use Test::Most tests => 60;
use Test::Moose;
use Module::Find;
use Archive::Zip::MemberRead;
use lib 'lib';
use MSWord::ToHTML;
use MSWord::ToHTML::Types::Library qw/:all/;

my @docs  = glob('t/data/*.doc');
my @docxs = glob('t/data/*.docx');

my $converter = MSWord::ToHTML->new;

for my $doc (@docs) {
    my ($new_doc,$html);
    lives_ok {  $new_doc = $converter->validate_file($doc) } "I can still validate";
    lives_ok { $html = $new_doc->get_html } "I can get html";
    isa_ok($html, "MSWord::ToHTML::HTML");
    can_ok($html, qw/file images/);
    can_ok($html->images, qw/children/) if $html->images;
}

for my $docx (@docxs) {
    my ($new_docx,$html);
    lives_ok {  $new_docx = $converter->validate_file($docx) } "I can still validate";
    lives_ok { $html = $new_docx->get_html } "I can get html";
    isa_ok($html, "MSWord::ToHTML::HTML");
    can_ok($html, qw/file images/);
    can_ok($html->images, qw/children/) if $html->images;
}
