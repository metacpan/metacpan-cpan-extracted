module github.com/example/my-project

go 1.16

// these are comments

exclude (
	example.com/whatmodule v1.4.0
)

replace (
	github.com/example/my-project/pkg/app => ./pkg/app
	github.com/example/my-project/pkg/app/client => ./pkg/app/client
)

require (
	github.com/dgrijalva/jwt-go v3.2.0+incompatible
	github.com/google/uuid v1.2.0
	golang.org/x/sys v0.0.0-20210510120138-977fb7262007 // indirect
)

exclude example.com/thismodule v1.3.0
exclude example.com/thatmodule v1.2.0
exclude example.com/thatmodule v1.1.0
replace github.com/example/my-project/pkg/old => ./pkg/new
require github.com/example/greatmodule v1.1.1
