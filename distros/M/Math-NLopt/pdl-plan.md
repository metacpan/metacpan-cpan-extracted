# Compile-time optional PDL ndarray support

## Summary

Detect PDL during `Makefile.PL` configuration.

- PDL available: build the PDL-aware XS bridge.
- PDL unavailable: build the native-array implementation only.
- PDL remains optional.

## Behavior

In a PDL-enabled build:

- Accept double piddles, coercing numeric ndarrays to double where necessary.
- Use `get_dataref` and contiguous underlying storage for direct C access.
- Return double piddles for vector or matrix results when the corresponding input is a piddle.
- Pass callback vectors as piddles, including `(n, m)` mconstraint gradients.
- Map PDL element `(j, k)` to NLopt’s C offset `gradient[k*n + j]`.
- Accept scalar callback returns as either Perl numbers or one-element/0-D piddles and normalize them to C doubles.

In a non-PDL-aware build:

- Detect a PDL object before normal array conversion.
- Throw a clear incompatibility exception:

  `Math::NLopt was built without PDL support; reinstall Math::NLopt with PDL installed to use PDL ndarrays`

- Do not attempt to treat a piddle as an arrayref.
- Preserve existing native-array behavior.

## Build and implementation

- Probe for `PDL::Core::Dev` during configuration.
- For enabled builds, add PDL include paths, `PDL_AUTO_INCLUDE`, `PDL_BOOT`, and the PDL feature macro.
- For disabled builds, omit all PDL headers, symbols, and boot code.
- Use PDL core allocation and wrapping APIs for returned and callback ndarrays.
- Preserve `optimize`’s current non-mutating caller-input behavior by using a writable double work ndarray.

## Tests and documentation

- Test both PDL-enabled and PDL-disabled builds.
- In the disabled build, verify piddles produce the reinstall guidance and native arrays still work.
- Test double coercion, direct storage, callback scalar ndarray returns, vector callbacks, and asymmetric `(n, m)` gradients.
- Update POD and generated README documentation with optional build support, ndarray shapes, callback behavior, and gradient storage order.
