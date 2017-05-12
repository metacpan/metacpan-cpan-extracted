#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::Select;
BEGIN {
  $HTML::FormFu::ExtJS::Element::Select::VERSION = '0.090';
}

use base "HTML::FormFu::ExtJS::Element::_Group";

use strict;
use warnings;
use utf8;
use Carp;

use JavaScript::Dumper;

sub render {
	my $class = shift;
	my $self  = shift;
	my $super = $class->SUPER::render($self);

    my $attrs = {};

    my $url = $super->{url};

    if($url && !$super->{id}) {
        carp 'Cannot create remote store without a field id';
        delete $super->{url};
    }

    if ($super->{store} && ref $super->{store} ne "SCALAR") {
	    $super->{store} = \"$super->{store}";
    } elsif ($super->{url}) {
        $attrs->{hiddenValue} = $self->default;
        $super->{value} = $super->{loading} || 'Loading...';
        delete $super->{loading};
        my $load_function;
        my $load_exception_function;
        if ($super->{multiple} && $super->{xtype} eq 'multiselect') {
            $attrs->{xtype} = 'multiselect';
            $load_function = "
                    var multiselect = Ext.getCmp('$super->{id}');
                    var value = multiselect.hiddenValue;
                    //multiselect.reset();
                    if (value) {
                        if (Ext.version = '3.0') {
                            multiselect.setValue(value);
                        }
                        else if (record = store.getById(value)) {
                            multiselect.setValue(record.data.text);
                        }
                    }";
            $load_exception_function = "
                    var combobox = Ext.getCmp('$super->{id}');
                    combobox.markInvalid(error || response.statusText);";
        }
        else {
            $load_function = "
                    var combobox = Ext.getCmp('$super->{id}');
                    var value = combobox.hiddenValue;
                    combobox.clearValue();
                    if (value) {
                        if (Ext.version = '3.0') {
                            combobox.setValue(value);
                        }
                        else if (record = store.getById(value)) {
                            combobox.setValue(record.data.text);
                        }
                    }";
            $load_exception_function = "
                    var combobox = Ext.getCmp('$super->{id}');
                    combobox.clearValue();
                    combobox.markInvalid(error || response.statusText);";
        }
        $super->{store} = \"new Ext.data.SimpleStore({
            fields:['value','text'],
            id:0,
            autoLoad:true,
            proxy:new Ext.data.HttpProxy({
                url:'$url',
                method:'GET',
                disableCaching:false
            }),
            listeners:{
                load:function(store, records, options) {
                    $load_function
                },
                loadexception:function(store, options, response, error) {
                    $load_exception_function
                }
            }
        })";
        delete $super->{url};
    } else {
        $attrs->{mode} = "local";
    	my $data;
    	foreach my $option ( @{ $self->render_data->{options} } ) {
    		push( @{$data}, [ $option->{value}, $option->{label} ] );
    		if($option->{group} && (my @groups = @{$option->{group}})) {
    			foreach my $item (@groups) {
    				push(@{$data}, [$item->{value},$item->{label}]);
    			}
    		}
    	}
    	my $string = js_dumper( { fields => [ "value", "text" ], data => $data } );
        $super->{store} = \("new Ext.data.SimpleStore(" . $string . ")");
    }

    return {
		editable       => \0,
		displayField   => "text",
        valueField     => "value",
        hiddenId       => $self->name . '_hidden',
		hiddenName     => $self->name,
		autoWidth      => \0,
		forceSelection => \1,
		triggerAction  => "all",
		xtype          => "combo",
		%{$super},
        %{$attrs}
	};

}



1;


__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::Select

=head1 VERSION

version 0.090

=head1 DESCRIPTION

Creates a select box.

The default ExtJS setup is:

  "mode"           : "local",
  "editable"       : false,
  "displayField"   : "text",
  "valueField"     : "value",
  "hiddenId"       : $self->name . '_hidden',
  "hiddenName"     : $self->name,
  "autoWidth"      : false,
  "forceSelection" : true,
  "triggerAction"  : "all",
  "store"          : new Ext.data.SimpleStore( ... ),
  "xtype"          : "combo"

This acts like a standard html select box. If you want a more ajaxish select box (e.g. editable) you can override these values with L</attrs|HTML::FormFu>.

The value of C<store> will always be unquoted. You can either provide a variable name which points to an instance
of an C<Ext.data.Store> class or create the instance right away.

=head2 MultiSelect

  - type: Select
    multiple: 1
    attrs:
      xtype: multiselect

Requires the MultiSelect user extension.

=head2 Remote Store

If you want to load the values of the combo box from an URL you can either create your own C<Ext.data.Store> instance
or let this class handle this.

=head3 Built-in remote store

  - type: Select
    name: combo
    id: unique_identifier
    attrs:
      url: /get_data

This will create a remote store instance which will fetch the data from C<url>. Make sure you give the 
select field an unique id. Otherwise the store will not be attached and a warning is thrown.

You can customize the text which is shown while the store is being loaded. It defaults to C<Loading...> and 
can be changed by setting the C<loading> attribute:

- type: Select
  name: combo
  id: unique_identifier
  attrs:
    url: /get_data
    loading: Wird geladen...

=head3 Custom C<Ext.data.Store> instance

    var dataStore = new Ext.data.JsonStore({
        url: '/get_data',
        root: 'rows',
        fields: ["text", "id"]
    });

C</get_data> has to return a data structure like this:

    {
       "rows" : [
          {
             "text" : "Item #1",
             "value" : "1234"
          }
       ]
    }

To add that store to your Select field, the configuration has to look like this:

  - type: Select
    name: combo
    attrs:
      store: dataStore

You can also overwrite the field names for C<valueField> and C<displayField> by adding them to the C<attrs>:

    - type: Select
      name: combo
      attrs:
        store: dataStore
        valueField: title
        displayField: id

Make sure that the store is loaded before you call C<form.load()> on that form. Otherwise the combo box field cannot
resolve the value to the corresponding label.

=head1 NAME

HTML::FormFu::ExtJS::Element::Select - Select box

=head1 SEE ALSO

L<HTML::FormFu::Element::Text>

=head1 AUTHORS

Moritz Onken (mo)

Alexander Hartmaier (abraxxa)

=head1 COPYRIGHT & LICENSE

Copyright 2009 Moritz Onken, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

