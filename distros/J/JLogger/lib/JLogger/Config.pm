package JLogger::Config;

use strict;
use warnings;

use YAML();

sub new {
    bless {}, shift;
}

sub load {
    my ($self, $config_text) = @_;

    my $config = YAML::Load($config_text);

    $self->_fix_element($config, 'transport');
    $self->_fix_elements($config, 'storages');
    $self->_fix_elements($config, 'filters');

    $config;
}

sub load_file {
    my ($self, $config_file) = @_;

    open my $fh, '<:encoding(UTF-8)', $config_file,
        or die qq(Can't open "$config_file": $!);

    my $config_text = do {
        local $/;
        <$fh>;
    };

    close $fh;

    $self->load($config_text);
}

sub _fix_element {
    my ($self, $config, $element_key) = @_;

    $config->{$element_key} =
      $self->_fix_element_value($config->{$element_key})
      if exists $config->{$element_key};
}

sub _fix_elements {
    my ($self, $config, $elements_key) = @_;

    if (exists $config->{$elements_key}) {
        $_ = $self->_fix_element_value($_) for @{$config->{$elements_key}};
    }
}

sub _fix_element_value {
    my ($self, $element) = @_;

    my $ref = ref $element;
    if ($ref eq '') {
        return [$element];
    }
    elsif ($ref eq 'HASH') {
        return [%$element];
    }

    $element;
}

1;
