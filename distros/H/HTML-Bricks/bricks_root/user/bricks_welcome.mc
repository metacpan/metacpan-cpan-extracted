%#----------------------------------------------------------------------------
%# brick: bricks_welcome
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
        'data' => {
          'text' => '<link rel="stylesheet" type="text/css" href="/webnoir.css">'
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
                  'rcol' => [],
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
                      'data' => {
                        'text' => 'Bricks'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'title',
                    'align' => 'right'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => '&nbsp;Site&nbsp;Builder'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'title'
                  }
                },
                'name' => 'column'
              }
            ],
            [
              {
                'data' => {
                  'rcol' => [],
                  'rprops' => {}
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => 'It\'s&nbsp;the'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'subtitle',
                    'align' => 'right'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => '&nbsp;kick-assest'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'class' => 'subtitle'
                  }
                },
                'name' => 'column'
              }
            ]
          ],
          'ncols' => 3,
          'nrows' => 2
        },
        'name' => 'table'
      },
      {
        'data' => {
          'text' => '<p>
&nbsp;
<p>'
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
                        'sort_order' => 'desc',
                        'description' => undef,
                        'sort_by' => 'mtime',
                        'name' => 'bricks blog'
                      },
                      'name' => 'weblog'
                    }
                  ],
                  'rprops' => {
                    'class' => 'weblog',
                    'align' => 'center',
                    'width' => '100%',
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
                        'rprops' => {
                          'height' => '600',
                          'cellpadding' => '0',
                          'width' => '1',
                          'bgcolor' => 'gray',
                          'cellspacing' => '0'
                        },
                        'rrows' => [
                          [
                            {
                              'data' => {
                                'rcol' => [
                                  {
                                    'data' => {
                                      'text' => '<span class="subtitle">Scout, the Bricks Site Builder mascot</span>
'
                                    },
                                    'name' => 'text'
                                  },
                                  {
                                    'data' => {
                                      'rprops' => {},
                                      'frozen_file_open' => {
                                        'data' => {
                                          'path' => '',
                                          'folder_mode' => 'list',
                                          'rtypes' => [
                                            [
                                              '.*',
                                              'all files'
                                            ]
                                          ],
                                          'name' => 'scout250.jpg',
                                          'rdests' => [
                                            '/'
                                          ],
                                          'filter' => '.*',
                                          'type' => 'open',
                                          'root_dir' => '/usr/local/www/htdocs'
                                        },
                                        'name' => 'fileselect'
                                      },
                                      'mode' => undef,
                                      'filename' => '/scout250.jpg'
                                    },
                                    'name' => 'image'
                                  },
                                  {
                                    'data' => {
                                      'text' => '<p>'
                                    },
                                    'name' => 'text'
                                  },
                                  {
                                    'data' => {},
                                    'name' => 'useraccess'
                                  }
                                ],
                                'rprops' => {
                                  'align' => 'center',
                                  'width' => '100%',
                                  'valign' => 'top',
                                  'bgcolor' => '#888888'
                                }
                              },
                              'name' => 'column'
                            }
                          ]
                        ],
                        'ncols' => 1,
                        'nrows' => 1
                      },
                      'name' => 'table'
                    }
                  ],
                  'rprops' => {
                    'valign' => 'top'
                  }
                },
                'name' => 'column'
              }
            ]
          ],
          'ncols' => 2,
          'nrows' => 1
        },
        'name' => 'table'
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
                      'data' => {},
                      'name' => 'version'
                    }
                  ],
                  'rprops' => {
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
                        'dpy_cright' => 'copyright&nbsp;&copy;&nbsp;',
                        'start_year' => '2001',
                        'dpy_cent' => 'checked'
                      },
                      'name' => 'copyright'
                    }
                  ],
                  'rprops' => {
                    'align' => 'center'
                  }
                },
                'name' => 'column'
              },
              {
                'data' => {
                  'rcol' => [
                    {
                      'data' => {
                        'text' => '<a href="http://www.sourceforge.net/projects/bricks">www.sourceforge.net/projects/bricks</a>'
                      },
                      'name' => 'text'
                    }
                  ],
                  'rprops' => {
                    'width' => '1',
                    'align' => 'right'
                  }
                },
                'name' => 'column'
              }
            ]
          ],
          'ncols' => 3,
          'nrows' => 1
        },
        'name' => 'table'
      },
      {
        'data' => {},
        'name' => 'weblog'
      }
    ],
    'rprops' => {
      'use_props' => 'self',
      'title' => 'welcome to bricks site builder',
      'body' => 'bgcolor="gray" color="#9f9f9f"',
      'doctype' => 'HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"',
      'rmetas' => []
    },
    'prev_modified_defined' => -1,
    'mode' => undef,
    'frozen_file_save_as' => {
      'data' => {
        'folder_mode' => 'list',
        'path' => '/user',
        'rtypes' => [
          [
            '.*',
            'all files'
          ]
        ],
        'name' => 'bricks_welcome.mc',
        'rdests' => [
          '/'
        ],
        'filter' => '.*',
        'type' => undef,
        'root_dir' => '/usr/local/bin/bricks'
      },
      'name' => 'fileselect'
    }
  },
  'name' => 'bricks_welcome'
};
</%once>
