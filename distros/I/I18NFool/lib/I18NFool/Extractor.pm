package I18NFool::Extractor; 
use MKDoc::XML::TreeBuilder;
use Locale::PO;
use warnings;
use strict;

our $Namespace = "http://xml.zope.org/namespaces/i18n";
our $Prefix    = 'i18n';
our $Domain    = 'default';
our $Results   = {};


sub process
{
    my $class = shift;
    my $data  = shift;
    
    local $Namespace = $Namespace;
    local $Prefix    = $Prefix;
    local $Domain    = $Domain;
    local $Results   = {};
    
    my @nodes = MKDoc::XML::TreeBuilder->process_data ($data);
    for (@nodes) { $class->_process ($_) }
    return $Results;
}


sub _process
{
    my $class = shift;
    my $tree  = shift;
    return unless (ref $tree);

    local $Prefix = $Prefix;
    local $Domain = $Domain;

    # process the I18N namespace
    foreach my $key (keys %{$tree})
    {
        my $value = $tree->{$key};
        if ($value eq $Namespace)
        {
            next unless ($key =~ /^xmlns\:/);
            delete $tree->{$key};
            $Prefix = $key;
            $Prefix =~ s/^xmlns\://;
        }
    }

    # set the current i18n:domain
    $Domain = delete $tree->{"$Prefix:domain"} || $Domain;

    my $tag  = $tree->{_tag};
    my $attr = { map { /^_/ ? () : ( $_ => $tree->{$_} ) } keys %{$tree} };
    return if ($tag eq '~comment' or $tag eq '~pi' or $tag eq '~declaration');
    
    # lookup for attributes...
    $tree->{"$Prefix:attributes"} && do {
        my $attributes = $tree->{"$Prefix:attributes"};
        $attributes =~ s/\s*;\s*$//;
        $attributes =~ s/^\s*//;
        my @attributes = split /\s*\;\s*/, $attributes;
        foreach my $attribute (@attributes)
        {
            # if we have i18n:attributes="alt alt_text", then the
            # attribute name is 'alt' and the
            # translate_id is 'alt_text'
            my ($attribute_name, $translate_id);
            if ($attribute =~ /\s/)
            {
                ($attribute_name, $translate_id) = split /\s+/, $attribute, 2;
            }

            # otherwise, if we have i18n:attributes="alt", then the
            # attribute name is 'alt' and the
            # translate_id is $tree->{'alt'}
            else
            {
                $attribute_name = $attribute;
                $translate_id = _canonicalize ( $tree->{$attribute_name} );
            }

            $translate_id || next;
            $Results->{$Domain} ||= {};

            my $existing_po = $Results->{$Domain}->{$translate_id};
            my $new_po = Locale::PO->new (
                -msgid  => $translate_id,
                -msgstr => _canonicalize ( $tree->{$attribute_name} ) || '',
            );

            if ($existing_po && ($existing_po->{msgstr} ne $new_po->{msgstr}))
            {
                print STDERR "String for '$translate_id' doesn't match:\n".
                             "   old: $existing_po->{msgstr}\n".
                             "   new: $new_po->{msgstr}\n"
            }

            $Results->{$Domain}->{$translate_id} = $new_po;
        }
    };

    # lookup for content...
    exists $tree->{"$Prefix:translate"} && do {
        my ($translate_id);

        # if we have $Domain:translate="something",
        # then the translate_id is 'something'
        if (defined $tree->{"$Prefix:translate"} and $tree->{"$Prefix:translate"} ne '')
        {
            $translate_id = $tree->{"$Prefix:translate"};
        }

        # otherwise, the translate_id has to be computed
        # from the contents of this node, so that
        # <div i18n:translate="">Hello, <span i18n:name="user">David</span>, how are you?</div>
        # becomes 'Hello, ${user}, how are you?'
        else
        {
            $translate_id = _canonicalize ( _extract_content_string ($tree) );
        }

        $translate_id || next;
        $Results->{$Domain} ||= {};

        my $existing_po = $Results->{$Domain}->{$translate_id};
        my $new_po = Locale::PO->new (
            -msgid  => $translate_id,
            -msgstr => _canonicalize ( _extract_content_string ($tree) ) || '',
        );

        if ($existing_po && ($existing_po->{msgstr} ne $new_po->{msgstr}))
        {
            print STDERR "String for '$translate_id' doesn't match:\n".
                         "   old: $existing_po->{msgstr}\n".
                         "   new: $new_po->{msgstr}\n"
        }

        $Results->{$Domain}->{$translate_id} = $new_po;
    };

    # I know, I know, the I18N namespace processing is a bit broken...
    # It should suffice for now
    delete $tree->{"$Prefix:attributes"};
    delete $tree->{"$Prefix:translate"};
    delete $tree->{"$Prefix:name"};

    # Do the same i18n thing with child nodes, recursively.
    # for some reason it always makes me think of roller coasters.
    # Yeeeeeeee!
    defined $tree->{_content} and do {
        for (@{$tree->{_content}}) { $class->_process ($_) }
    };
}


sub _canonicalize
{
    my $string = shift || '';
    $string =~ s/\r/ /g;
    $string =~ s/\n/ /g;
    $string =~ s/\s+/ /gsm;
    $string =~ s/^ //;
    $string =~ s/ $//;
    return $string;
}


sub _extract_content_string
{
    my $tree  = shift;
    my @res   = ();

    my $count = 0;
    foreach my $node (@{$tree->{_content}})
    {
        ref $node or do {
            push @res, $node;
            next;
        };
        
        $count++;
        my $name = $node->{"$Prefix:name"} || $count;
        push @res, '${' . $name . '}';
    }
    
    return join '', @res;
}


1;
