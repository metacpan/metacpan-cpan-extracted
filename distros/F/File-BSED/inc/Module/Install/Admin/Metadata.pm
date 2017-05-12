package Module::Install::Admin::Metadata;

use Module::Install::Base;
@ISA = 'Module::Install::Base';

$VERSION = '0.67';

use strict;

sub remove_meta {
    my $self = shift;
    my $package = ref($self->_top);
    my $version = $self->_top->VERSION;

    return unless -f 'META.yml';
    open META, 'META.yml'
      or die "Can't open META.yml for output:\n$!";
    my $meta = do {local $/; <META>};
    close META;
    return unless $meta =~ /^generated_by: $package version $version/m;
    unless (-w 'META.yml') {
        warn "Can't remove META.yml file. Not writable.\n";
        return;
    }
    warn "Removing auto-generated META.yml\n";
    unlink 'META.yml'
      or die "Couldn't unlink META.yml:\n$!";
}

sub write_meta {
    my $self = shift;

    META_NOT_OURS: {
        local *FH;
        if ( open FH, "META.yml" ) {
            while (<FH>) {
                last META_NOT_OURS if /^generated_by: Module::Install\b/;
            }
            return if -s FH;
        }
    }

    print "Writing META.yml\n";

    local *META;
    open META, "> META.yml" or warn "Cannot write to META.yml: $!";
    print META $self->dump_meta;
    close META;

    return;
}

sub dump_meta {
    my $self    = shift;
    my $package = ref( $self->_top );
    my $version = $self->_top->VERSION;
    my %values  = %{ $self->Meta->{'values'} };

    delete $values{sign};

    if ( my $perl_version = delete $values{perl_version} ) {
        # Always canonical to three-dot version
        $perl_version =~
            s{^(\d+)\.(\d\d\d)(\d*)}{join('.', $1, int($2||0), int($3||0))}e
            if $perl_version >= 5.006;
        $values{requires} = [
            [ perl => $perl_version ],
            @{ $values{requires} || [] },
        ];
    }

        # Set a default 'unknown' license
    unless ( $values{license} ) {
        warn "No license specified, setting license = 'unknown'\n";
        $values{license} = 'unknown';
    }

    $values{distribution_type} ||= 'module';

        # Guess a name if needed, derived from the module_name
    if ( $values{module_name} and ! $values{name} ) {
        $values{name} = $values{module_name};
        $values{name} =~ s/::/-/g;
    }

    if ( $values{name} =~ /::/ ) {
        my $name = $values{name};
        $name =~ s/::/-/g;
        die "Error in name(): '$values{name}' should be '$name'!\n";
    }

    my %dump;
    foreach my $key ($self->Meta_ScalarKeys) {
        $dump{$key} = $values{$key} if exists $values{$key};
    }
    foreach my $key ($self->Meta_TupleKeys) {
        next unless exists $values{$key};
        $dump{$key} = { map { @$_ } @{ $values{$key} } };
    }

    if ( my $provides = $values{provides} ) {
        $dump{provides} = $provides;
    }

    my $no_index = $values{no_index} ||= {};
    push @{ $no_index->{'directory'} ||= [] }, 'inc', 't';
    $dump{no_index} = $no_index;
    $dump{generated_by} = "$package version $version";

    # Add mention of the META spec
    $dump{"meta-spec"} = {
        version => 1.3,
        url => 'http://module-build.sourceforge.net/META-spec-v1.3.html',
    };

    local $@;
    if (eval { require YAML::Syck }) {
# Why no header? It is required by the spec!
#        local $YAML::Syck::Headless = 1;
        return YAML::Syck::Dump(\%dump);
    }
    elsif (eval { require YAML::Tiny }) {
        return YAML::Tiny::Dump(\%dump);
    }
    else {
        require YAML;
# Why no header? It is required by the spec!
#        local $YAML::UseHeader = 0;
        return YAML::Dump(\%dump);
    }
}

1;
