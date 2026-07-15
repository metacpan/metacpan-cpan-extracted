use strict;
use warnings;
use Test::More;
use Eshu;

sub jn { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 2) }

# ── already-formatted snippets ─────────────────────────────────────

# 1. flat object
{
    my $code = <<'END';
{
  "name": "Alice",
  "age": 30,
  "active": true
}
END
    is(jn($code), $code, 'JSON: flat object');
}

# 2. nested object
{
    my $code = <<'END';
{
  "user": {
    "id": 1,
    "name": "Bob",
    "address": {
      "street": "123 Main St",
      "city": "Springfield",
      "zip": "12345"
    }
  }
}
END
    is(jn($code), $code, 'JSON: nested object');
}

# 3. array of strings
{
    my $code = <<'END';
{
  "tags": [
    "perl",
    "python",
    "javascript",
    "rust",
    "go"
  ]
}
END
    is(jn($code), $code, 'JSON: array of strings');
}

# 4. array of objects
{
    my $code = <<'END';
{
  "users": [
    {
      "id": 1,
      "name": "Alice"
    },
    {
      "id": 2,
      "name": "Bob"
    },
    {
      "id": 3,
      "name": "Carol"
    }
  ]
}
END
    is(jn($code), $code, 'JSON: array of inline objects');
}

# 5. package.json
{
    my $code = <<'END';
{
  "name": "my-app",
  "version": "1.0.0",
  "description": "A sample application",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "jest",
    "build": "webpack --mode production",
    "lint": "eslint src/"
  },
  "dependencies": {
    "express": "^4.18.2",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "eslint": "^8.0.0"
  }
}
END
    is(jn($code), $code, 'JSON: package.json');
}

# 6. tsconfig.json
{
    my $code = <<'END';
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "lib": [
      "ES2022",
      "DOM"
    ],
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": [
    "src/**/*.ts"
  ],
  "exclude": [
    "node_modules",
    "dist"
  ]
}
END
    is(jn($code), $code, 'JSON: tsconfig.json');
}

# 7. API response
{
    my $code = <<'END';
{
  "status": "success",
  "data": {
    "total": 3,
    "page": 1,
    "per_page": 10,
    "items": [
      {
        "id": "abc123",
        "title": "First Item",
        "created_at": "2024-01-01T00:00:00Z"
      },
      {
        "id": "def456",
        "title": "Second Item",
        "created_at": "2024-01-02T00:00:00Z"
      }
    ]
  },
  "meta": {
    "request_id": "req_xyz789",
    "duration_ms": 42
  }
}
END
    is(jn($code), $code, 'JSON: paginated API response');
}

# 8. GeoJSON
{
    my $code = <<'END';
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [
          -122.4194,
          37.7749
        ]
      },
      "properties": {
        "name": "San Francisco",
        "population": 883305
      }
    }
  ]
}
END
    is(jn($code), $code, 'JSON: GeoJSON FeatureCollection');
}

# 9. OpenAPI fragment
{
    my $code = <<'END';
{
  "openapi": "3.1.0",
  "info": {
    "title": "Pet Store API",
    "version": "1.0.0"
  },
  "paths": {
    "/pets": {
      "get": {
        "summary": "List all pets",
        "operationId": "listPets",
        "tags": [
          "pets"
        ],
        "responses": {
          "200": {
            "description": "A list of pets",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/PetList"
                }
              }
            }
          }
        }
      }
    }
  }
}
END
    is(jn($code), $code, 'JSON: OpenAPI fragment');
}

# 10. JSON Schema
{
    my $code = <<'END';
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "User",
  "type": "object",
  "required": [
    "id",
    "name",
    "email"
  ],
  "properties": {
    "id": {
      "type": "integer",
      "minimum": 1
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 100
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "role": {
      "type": "string",
      "enum": [
        "admin",
        "user",
        "guest"
      ]
    }
  },
  "additionalProperties": false
}
END
    is(jn($code), $code, 'JSON: JSON Schema');
}

# 11. ESLint config
{
    my $code = <<'END';
{
  "env": {
    "browser": true,
    "es2022": true,
    "node": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": "error",
    "prefer-const": "error",
    "eqeqeq": [
      "error",
      "always"
    ]
  }
}
END
    is(jn($code), $code, 'JSON: ESLint config');
}

# 12. Babel config
{
    my $code = <<'END';
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": "> 0.25%, not dead",
        "useBuiltIns": "usage",
        "corejs": 3
      }
    ],
    "@babel/preset-typescript",
    "@babel/preset-react"
  ],
  "plugins": [
    "@babel/plugin-transform-runtime",
    "babel-plugin-styled-components"
  ]
}
END
    is(jn($code), $code, 'JSON: Babel config');
}

# 13. VS Code settings
{
    my $code = <<'END';
{
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "files.exclude": {
    "**/node_modules": true,
    "**/.git": true,
    "**/dist": true
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "typescript.preferences.importModuleSpecifier": "relative"
}
END
    is(jn($code), $code, 'JSON: VS Code settings');
}

# 14. npm lock entry stub
{
    my $code = <<'END';
{
  "node_modules/express": {
    "version": "4.18.2",
    "resolved": "https://registry.npmjs.org/express/-/express-4.18.2.tgz",
    "license": "MIT",
    "dependencies": {
      "accepts": "~1.3.8",
      "array-flatten": "1.1.1"
    },
    "engines": {
      "node": ">= 0.10.0"
    }
  }
}
END
    is(jn($code), $code, 'JSON: package-lock.json entry stub');
}

# 15. deeply nested
{
    my $code = <<'END';
{
  "level1": {
    "level2": {
      "level3": {
        "level4": {
          "value": 42,
          "array": [
            1,
            2,
            3
          ],
          "nested": {
            "deep": true
          }
        }
      }
    }
  }
}
END
    is(jn($code), $code, 'JSON: deeply nested object');
}

# 16. mixed types
{
    my $code = <<'END';
{
  "string": "hello",
  "number": 3.14,
  "integer": 42,
  "boolean_true": true,
  "boolean_false": false,
  "null_value": null,
  "array": [
    1,
    "two",
    true,
    null,
    {
      "key": "val"
    }
  ],
  "object": {
    "a": 1,
    "b": 2
  }
}
END
    is(jn($code), $code, 'JSON: all value types');
}

# 17. GitHub Actions workflow (JSON equiv)
{
    my $code = <<'END';
{
  "name": "CI",
  "on": {
    "push": {
      "branches": [
        "main"
      ]
    },
    "pull_request": {
      "branches": [
        "main"
      ]
    }
  },
  "jobs": {
    "test": {
      "runs-on": "ubuntu-latest",
      "steps": [
        {
          "uses": "actions/checkout@v4"
        },
        {
          "uses": "actions/setup-node@v4",
          "with": {
            "node-version": "20"
          }
        },
        {
          "run": "npm ci"
        },
        {
          "run": "npm test"
        }
      ]
    }
  }
}
END
    is(jn($code), $code, 'JSON: GitHub Actions workflow');
}

# 18. empty containers
{
    my $code = <<'END';
{
  "empty_object": {},
  "empty_array": [],
  "nested_empty": {
    "also_empty": {},
    "arr": []
  }
}
END
    is(jn($code), $code, 'JSON: empty objects and arrays');
}

# 19. unicode strings
{
    my $code = <<'END';
{
  "greeting_en": "Hello, World!",
  "greeting_ja": "こんにちは",
  "greeting_ar": "مرحبا",
  "emoji": "😀🌍",
  "escaped": "Line1\nLine2\tTabbed"
}
END
    is(jn($code), $code, 'JSON: unicode escape sequences');
}

# 20. array at top level
{
    my $code = <<'END';
[
  {
    "id": 1,
    "name": "first"
  },
  {
    "id": 2,
    "name": "second"
  },
  {
    "id": 3,
    "name": "third"
  }
]
END
    is(jn($code), $code, 'JSON: top-level array of objects');
}

# 21. large numbers and special floats
{
    my $code = <<'END';
{
  "max_safe_int": 9007199254740991,
  "negative": -42,
  "float": 3.141592653589793,
  "scientific": 1.5e10,
  "negative_scientific": -2.5e-3,
  "zero": 0
}
END
    is(jn($code), $code, 'JSON: numeric values');
}

# 22. Prettier config
{
    my $code = <<'END';
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf"
}
END
    is(jn($code), $code, 'JSON: Prettier config');
}

# 23. Docker Compose (JSON form)
{
    my $code = <<'END';
{
  "version": "3.9",
  "services": {
    "app": {
      "build": ".",
      "ports": [
        "3000:3000"
      ],
      "environment": {
        "NODE_ENV": "production",
        "DATABASE_URL": "postgres://db/app"
      },
      "depends_on": [
        "db",
        "redis"
      ]
    },
    "db": {
      "image": "postgres:15",
      "volumes": [
        "pgdata:/var/lib/postgresql/data"
      ],
      "environment": {
        "POSTGRES_DB": "app",
        "POSTGRES_PASSWORD": "secret"
      }
    },
    "redis": {
      "image": "redis:7-alpine"
    }
  },
  "volumes": {
    "pgdata": {}
  }
}
END
    is(jn($code), $code, 'JSON: Docker Compose');
}

# 24. manifest with multiple arrays
{
    my $code = <<'END';
{
  "manifest_version": 3,
  "name": "My Extension",
  "version": "1.0.0",
  "permissions": [
    "storage",
    "tabs",
    "activeTab"
  ],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": [
        "<all_urls>"
      ],
      "js": [
        "content.js"
      ],
      "css": [
        "styles.css"
      ]
    }
  ]
}
END
    is(jn($code), $code, 'JSON: Chrome extension manifest v3');
}

# 25. i18n translation file
{
    my $code = <<'END';
{
  "common": {
    "ok": "OK",
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "loading": "Loading..."
  },
  "errors": {
    "required": "This field is required",
    "invalid_email": "Please enter a valid email address",
    "too_short": "Must be at least {{min}} characters",
    "too_long": "Must be at most {{max}} characters"
  },
  "nav": {
    "home": "Home",
    "about": "About",
    "contact": "Contact"
  }
}
END
    is(jn($code), $code, 'JSON: i18n translation file');
}

# ── normalization tests ────────────────────────────────────────────

# 26
{
    my $in = <<'END';
{"name":"Alice","age":30,"active":true}
END
    my $exp = <<'END';
{
  "name": "Alice",
  "age": 30,
  "active": true
}
END
    is(jn($in), $exp, 'JSON: minified object expanded');
}

# 27
{
    my $in = <<'END';
{"users":[{"id":1,"name":"Bob"},{"id":2,"name":"Carol"}]}
END
    my $exp = <<'END';
{
  "users": [
    {
      "id": 1,
      "name": "Bob"
    },
    {
      "id": 2,
      "name": "Carol"
    }
  ]
}
END
    is(jn($in), $exp, 'JSON: minified nested array expanded');
}

# 28
{
    my $in = <<'END';
{"scripts":{"start":"node index.js","test":"jest","build":"webpack"}}
END
    my $exp = <<'END';
{
  "scripts": {
    "start": "node index.js",
    "test": "jest",
    "build": "webpack"
  }
}
END
    is(jn($in), $exp, 'JSON: minified scripts section expanded');
}

# 29 — 4-space indented input normalised to 2-space
{
    my $in = <<'END';
{
    "host": "localhost",
    "port": 3000,
    "debug": false
}
END
    my $exp = <<'END';
{
  "host": "localhost",
  "port": 3000,
  "debug": false
}
END
    is(jn($in), $exp, 'JSON: 4-space indent normalised to 2-space');
}

# 30 — tab-indented input normalised to 2-space
{
    my $in = "{\n\t\"key\": \"value\",\n\t\"num\": 42\n}\n";
    my $exp = <<'END';
{
  "key": "value",
  "num": 42
}
END
    is(jn($in), $exp, 'JSON: tab indent normalised to 2-space');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "{\"a\":1,\"b\":2,\"c\":3}\n",
    "[1,2,3,4,5]\n",
    "{\"nested\":{\"deep\":{\"value\":true}}}\n",
    "{\"arr\":[{\"x\":1},{\"x\":2},{\"x\":3}]}\n",
    "{\"mixed\":[1,\"two\",true,null,{\"key\":\"val\"}]}\n",
    "[{\"id\":1,\"tags\":[\"a\",\"b\"]},{\"id\":2,\"tags\":[\"c\"]}]\n",
    "{\"empty_obj\":{},\"empty_arr\":[]}\n",
    "{\"config\":{\"database\":{\"host\":\"localhost\",\"port\":5432},\"cache\":{\"ttl\":300}}}\n",
    "{\"permissions\":[\"read\",\"write\",\"delete\"],\"roles\":{\"admin\":[\"read\",\"write\",\"delete\"],\"user\":[\"read\"]}}\n",
    "[\"alpha\",\"beta\",\"gamma\",\"delta\",\"epsilon\"]\n",
) {
    my $once = jn($snippet);
    is(jn($once), $once, 'JSON: snippet idempotent');
}

done_testing;
