package Faker;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Data::Object::Role::Proxyable';
with 'Faker::Maker';

our $VERSION = '1.04'; # VERSION

# METHODS

method address_city_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_city_name', %args)->execute;
}

method address_city_prefix(%args) {
  $args{faker} = $self;

  return $self->plugin('address_city_prefix', %args)->execute;
}

method address_city_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('address_city_suffix', %args)->execute;
}

method address_country_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_country_name', %args)->execute;
}

method address_latitude(%args) {
  $args{faker} = $self;

  return $self->plugin('address_latitude', %args)->execute;
}

method address_line1(%args) {
  $args{faker} = $self;

  return $self->plugin('address_line1', %args)->execute;
}

method address_line2(%args) {
  $args{faker} = $self;

  return $self->plugin('address_line2', %args)->execute;
}

method address_lines(%args) {
  $args{faker} = $self;

  return $self->plugin('address_lines', %args)->execute;
}

method address_longitude(%args) {
  $args{faker} = $self;

  return $self->plugin('address_longitude', %args)->execute;
}

method address_number(%args) {
  $args{faker} = $self;

  return $self->plugin('address_number', %args)->execute;
}

method address_postal_code(%args) {
  $args{faker} = $self;

  return $self->plugin('address_postal_code', %args)->execute;
}

method address_state_abbr(%args) {
  $args{faker} = $self;

  return $self->plugin('address_state_abbr', %args)->execute;
}

method address_state_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_state_name', %args)->execute;
}

method address_street_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_street_name', %args)->execute;
}

method address_street_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('address_street_suffix', %args)->execute;
}

method build_proxy($package, $method, %args) {
  $args{faker} = $self;

  my $under = delete $args{under};

  $method = "$under/$method" if $under;

  if (my $plugin = eval { $self->plugin($method, %args) }) {

    return sub { $plugin->execute };
  }

  return undef;
}

method color_hex_code(%args) {
  $args{faker} = $self;

  return $self->plugin('color_hex_code', %args)->execute;
}

method color_name(%args) {
  $args{faker} = $self;

  return $self->plugin('color_name', %args)->execute;
}

method color_rgbcolors(%args) {
  $args{faker} = $self;

  return $self->plugin('color_rgbcolors', %args)->execute;
}

method color_rgbcolors_array(%args) {
  $args{faker} = $self;

  return $self->plugin('color_rgbcolors_array', %args)->execute;
}

method color_rgbcolors_css(%args) {
  $args{faker} = $self;

  return $self->plugin('color_rgbcolors_css', %args)->execute;
}

method color_safe_hex_code(%args) {
  $args{faker} = $self;

  return $self->plugin('color_safe_hex_code', %args)->execute;
}

method color_safe_name(%args) {
  $args{faker} = $self;

  return $self->plugin('color_safe_name', %args)->execute;
}

method company_buzzword_type1(%args) {
  $args{faker} = $self;

  return $self->plugin('company_buzzword_type1', %args)->execute;
}

method company_buzzword_type2(%args) {
  $args{faker} = $self;

  return $self->plugin('company_buzzword_type2', %args)->execute;
}

method company_buzzword_type3(%args) {
  $args{faker} = $self;

  return $self->plugin('company_buzzword_type3', %args)->execute;
}

method company_description(%args) {
  $args{faker} = $self;

  return $self->plugin('company_description', %args)->execute;
}

method company_jargon_buzz_word(%args) {
  $args{faker} = $self;

  return $self->plugin('company_jargon_buzz_word', %args)->execute;
}

method company_jargon_edge_word(%args) {
  $args{faker} = $self;

  return $self->plugin('company_jargon_edge_word', %args)->execute;
}

method company_jargon_prop_word(%args) {
  $args{faker} = $self;

  return $self->plugin('company_jargon_prop_word', %args)->execute;
}

method company_name(%args) {
  $args{faker} = $self;

  return $self->plugin('company_name', %args)->execute;
}

method company_name_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('company_name_suffix', %args)->execute;
}

method company_tagline(%args) {
  $args{faker} = $self;

  return $self->plugin('company_tagline', %args)->execute;
}

method internet_domain_name(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_domain_name', %args)->execute;
}

method internet_domain_word(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_domain_word', %args)->execute;
}

method internet_email_address(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_email_address', %args)->execute;
}

method internet_email_domain(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_email_domain', %args)->execute;
}

method internet_ip_address(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_ip_address', %args)->execute;
}

method internet_ip_address_v4(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_ip_address_v4', %args)->execute;
}

method internet_ip_address_v6(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_ip_address_v6', %args)->execute;
}

method internet_root_domain(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_root_domain', %args)->execute;
}

method internet_url(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_url', %args)->execute;
}

method lorem_paragraph(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_paragraph', %args)->execute;
}

method lorem_paragraphs(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_paragraphs', %args)->execute;
}

method lorem_sentence(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_sentence', %args)->execute;
}

method lorem_sentences(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_sentences', %args)->execute;
}

method lorem_word(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_word', %args)->execute;
}

method lorem_words(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_words', %args)->execute;
}

method payment_card_expiration(%args) {
  $args{faker} = $self;

  return $self->plugin('payment_card_expiration', %args)->execute;
}

method payment_card_number(%args) {
  $args{faker} = $self;

  return $self->plugin('payment_card_number', %args)->execute;
}

method payment_vendor(%args) {
  $args{faker} = $self;

  return $self->plugin('payment_vendor', %args)->execute;
}

method person_first_name(%args) {
  $args{faker} = $self;

  return $self->plugin('person_first_name', %args)->execute;
}

method person_last_name(%args) {
  $args{faker} = $self;

  return $self->plugin('person_last_name', %args)->execute;
}

method person_name(%args) {
  $args{faker} = $self;

  return $self->plugin('person_name', %args)->execute;
}

method person_name_prefix(%args) {
  $args{faker} = $self;

  return $self->plugin('person_name_prefix', %args)->execute;
}

method person_name_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('person_name_suffix', %args)->execute;
}

method person_username(%args) {
  $args{faker} = $self;

  return $self->plugin('person_username', %args)->execute;
}

method telephone_number(%args) {
  $args{faker} = $self;

  return $self->plugin('telephone_number', %args)->execute;
}

1;
