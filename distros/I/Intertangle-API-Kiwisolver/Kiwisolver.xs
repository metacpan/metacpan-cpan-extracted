#include <xs.h>
using namespace xs;

#include <kiwi/kiwi.h>

#include "Refcnt.xsi"

MODULE = Intertangle::API::Kiwisolver                PACKAGE = Intertangle::API::Kiwisolver
PROTOTYPES: DISABLE

BOOT {
	Stash(__PACKAGE__, GV_ADD).mark_as_loaded("Intertangle::API::Kiwisolver");
}

INCLUDE: Variable.xsi

INCLUDE: Term.xsi

INCLUDE: Expression.xsi

INCLUDE: Strength.xsi

INCLUDE: Constraint.xsi

INCLUDE: Solver.xsi

INCLUDE: Symbolics.xsi
