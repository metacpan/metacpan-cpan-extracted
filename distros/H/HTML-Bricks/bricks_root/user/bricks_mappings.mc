%#----------------------------------------------------------------------------
%# brick: bricks_mappings
%#
%# from here to "once" tag copied from 
%# $HTML::Bricks::Config{bricks_root}/assembly_template
%#----------------------------------------------------------------------------

%#----------------------------------------------------------------------------
%# new
%#----------------------------------------------------------------------------
<%method new>
<%perl>
  my $rbrick = shift;
  $rbrick->push_supers('assembly');
  $rbrick->super->new();
  $rbrick->thaw($rsaved_node1);
</%perl>
</%method>

%#---------------------------------------------------------------------------
%# thaw
%#---------------------------------------------------------------------------
<%method thaw>
<%perl>
  my ($rbrick, $rnode)  = @_;

  $rbrick->push_supers('assembly');
  $rbrick->super->new();

  my $rnode_data = $$rnode{data};
  
  if (exists $$rnode_data{rcol}) { 
    #
    # If we're passed in an actual frozen assembly, then thaw what's
    # passed in, else thaw the copy in this file
    #
 
    return $rbrick->super->thaw($rnode);
  }

  return $rbrick->super->thaw($rsaved_node1);
</%perl>
</%method>

%#---------------------------------------------------------------------------
%# is_assembly
%#---------------------------------------------------------------------------
<%method is_assembly>
<%perl>
  return 1;
</%perl>
</%method>

%#---------------------------------------------------------------------------
%# once
%#---------------------------------------------------------------------------
<%once>
  my $rsaved_node1 = {
  'data' => {
    'rcol' => [
      {
        'data' => {},
        'name' => 'mappings'
      },
      {
        'data' => {
          'text' => '<p>
The mapping of a given Universal Resource Indicator (URI) 
to one or more assemblies is controlled by this page.  Every
URI is tested one after another against the above mappings.  
If a test passes, then the assembly on the right-hand side is 
added to the end of a list of matching assemblies.  Those 
assemblies are then linked together to form an object graph 
that will render the HTML for the requested URI.
</p>

<p>
The ability to have multiple assemblies map to a given URI
allows the easy creation of headers, footers, menus, and the
like for a web-site. 
</p>

<p>
If no assemblies map to a given URI, Bricks will try to find a
matching html file.  If no html file exists, Bricks returns a
\'404 Not Found\' error.
</p>
'
        },
        'name' => 'text'
      }
    ],
    'rprops' => {},
    'prev_modified_defined' => undef,
    'mode' => undef,
    'frozen_file_save_as' => {
      'data' => {
        'folder_mode' => 'list',
        'rdests' => [
          '/'
        ],
        'filter' => '.*',
        'type' => undef,
        'root_dir' => '/usr/local/bin/bricks',
        'rtypes' => [
          [
            '.*',
            'all files'
          ]
        ]
      },
      'name' => 'fileselect'
    }
  },
  'name' => 'bricks_mappings'
};
</%once>
