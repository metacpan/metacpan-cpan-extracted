%#----------------------------------------------------------------------------
%# brick: authorbar
%#
%# from here to "once" tag coppied from 
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
        'data' => {
          'text' => '<style type="text/css">
<!--

.authorbar {
  font-family: veranda, arial, sans-serif;
  font-size: 14px;
  background: #888888;
  color: #5f5f5f;
}

a:link.authorbar {
  text-decoration: none;
  color: #cccccc;
}

a:visited.authorbar {
  text-decoration: none;
  color: #cccccc;
}

a:hover.authorbar {
  text-decoration: none;
  color: #eeeeee;
}

.edittag {
  font-family: veranda, arial, sans-serif;
  font-size: 14px;
  background: #808080;
  color: #bbbbbb;
}

a:link.edittag {
  text-decoration: none;
  color: #eeeeee;
}

a:visited.edittag {
  text-decoration: none;
  color: #eeeeee;
}

a:hover.edittag {
  text-decoration: none;
  color: #ffffff;
}

-->
</style>'
        },
        'name' => 'text'
      },
      {
        'data' => {
          'rprops' => {
            'cellpadding' => '0',
            'width' => '100%',
            'cellspacing' => '0'
          },
          'rrows' => [
            [
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'rprops' => {
                          'class' => 'authorbar',
                          'width' => '100%'
                        },
                        'rrows' => [
                          [
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'current' => undef
                                    },
                                    'name' => 'assyslist'
                                  }
                                ],
                                'rprops' => {
                                  'valign' => 'top',
                                  'width' => '1'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {},
                                    'name' => 'editviewbutton'
                                  }
                                ],
                                'rprops' => {
                                  'align' => 'left',
                                  'valign' => 'top',
                                  'width' => '1'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {},
                                    'name' => 'savebutton'
                                  }
                                ],
                                'rprops' => {
                                  'valign' => 'top'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {},
                                    'name' => 'saveasbutton'
                                  }
                                ],
                                'rprops' => {
                                  'valign' => 'top'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'text' => '&nbsp;'
                                    },
                                    'name' => 'text'
                                  }
                                ],
                                'rprops' => {
                                  'width' => '100%'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {},
                                    'name' => 'newbutton'
                                  }
                                ],
                                'rprops' => {
                                  'width' => '1',
                                  'valign' => 'top'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'text' => '<a class="authorbar" href="/bricks_open.html">open</a>'
                                    },
                                    'name' => 'text'
                                  }
                                ],
                                'rprops' => {
                                  'valign' => 'top',
                                  'width' => '1'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'text' => '<a class="authorbar" href="/bricks_mappings.html">mappings</a>'
                                    },
                                    'name' => 'text'
                                  }
                                ],
                                'rprops' => {
                                  'valign' => 'top',
                                  'width' => '1'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {},
                                    'name' => 'useraccess'
                                  }
                                ],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            }
                          ],
                          [
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'name' => 'editactions'
                                  }
                                ],
                                'rprops' => {
                                  'height' => '1',
                                  'width' => '1',
                                  'colspan' => '5'
                                }
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            },
                            {
                              'data' => {
                                'rcol' => [],
                                'rprops' => {}
                              },
                              'name' => 'column'
                            }
                          ]
                        ],
                        'ncols' => 9,
                        'nrows' => 2
                      },
                      'name' => 'table'
                    }
                  ],
                  'rprops' => {}
                },
                'name' => 'column'
              }
            ],
            [
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {},
                      'name' => 'next'
                    }
                  ],
                  'rprops' => {}
                },
                'name' => 'column'
              }
            ]
          ],
          'ncols' => 1,
          'nrows' => 2
        },
        'name' => 'table'
      }
    ],
    'rprops' => {
      'use_props' => 'child',
      'title' => 'bricks site builder',
      'body' => '',
      'doctype' => '',
      'rmetas' => []
    },
    'prev_modified_defined' => undef,
    'mode' => undef,
    'frozen_file_save_as' => {
      'data' => {
        'root_dir' => '/usr/local/bin/bricks'
      },
      'name' => 'fileselect'
    }
  },
  'name' => 'authorbar'
};
</%once>
