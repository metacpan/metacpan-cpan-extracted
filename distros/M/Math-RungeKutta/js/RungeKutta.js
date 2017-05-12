// RungeKutta.js
//########################################################################
//     This JavaScript module is Copyright (c) 2002, Peter J Billam      #
//               c/o P J B Computing, www.pjb.com.au                     #
//                                                                       #
//     This module is free software; you can redistribute it and/or      #
//            modify it under the same terms as Perl itself.             #
//     Documentation in http://search.cpan.org/~pjb/Math-RungeKutta      #
//########################################################################

// VERSION = '1.07';

function rk2 (ynref, dydtref, t, dt) {
	var gamma = 0.75;  // Ralston's minimisation of error bounds
	var alpha = 0.5/gamma; var beta = 1.0-gamma;
	var alphadt=alpha*dt; var betadt=beta*dt; var gammadt=gamma*dt;
	var ny = ynref.length;
	var ynp1 = new Array(ny);
	var dydtn = new Array(ny);
	var ynpalpha = new Array(ny);
	var dydtnpalpha = new Array(ny);

	dydtn = dydtref(t, ynref);
	var i; for (i=0; i<ny; i++) {
		ynpalpha[i] = ynref[i] + alphadt*dydtn[i];
	}
	dydtnpalpha = dydtref(t+alphadt, ynpalpha);
	for (i=0; i<ny; i++) {
		ynp1[i] = ynref[i]+betadt*dydtn[i]+gammadt*dydtnpalpha[i];
	}
	return [t+dt, ynp1];
}

var _rk_saved_k0 = new Array(); var _rk_use_saved_k0 = false;
function rk4 (ynref, dydtref, t, dt) {
	var ny = ynref.length; var i;

	var k0 = new Array(ny);
	if (_rk_use_saved_k0) {
		for (i=0; i<ny; i++) { k0[i] = _rk_saved_k0[i]; }
	} else { k0 = dydtref(t, ynref);
	}
	for (i=0; i<ny; i++) { k0[i] *= dt; }

	var eta1 = new Array(ny);
	for (i=0; i<ny; i++) { eta1[i] = ynref[i] + k0[i]/3.0; }
	var k1 = new Array(ny);
	k1 = dydtref(t + dt/3.0, eta1);
	for (i=0; i<ny; i++) { k1[i] *= dt; }

	var eta2 = new Array(ny);
	var k2 = new Array(ny);
	for (i=0; i<ny; i++) {
		eta2[i] = ynref[i] + (k0[i]+k1[i])/6.0;
	}
	k2 = dydtref(t + dt/3.0, eta2);
	for (i=0; i<ny; i++) { k2[i] *= dt; }

	var eta3 = new Array(ny);
	for (i=0; i<ny; i++) {
		eta3[i] = ynref[i] + (k0[i]+3.0*k2[i])*0.125;
	}
	var k3 = new Array(ny);
	k3 = dydtref(t+0.5*dt, eta3);
	for (i=0; i<ny; i++) { k3[i] *= dt; }

	var eta4 = new Array(ny);
	for (i=0; i<ny; i++) {
		eta4[i] = ynref[i] + (k0[i]-3.0*k2[i]+4.0*k3[i])*0.5;
	}
	var k4 = new Array(ny);
	k4 = dydtref(t+dt, eta4);
	for (i=0; i<ny; i++) { k4[i] *= dt; }

	var ynp1 = new Array(ny);
	for (i=0; i<ny; i++) {
		ynp1[i] = ynref[i] + (k0[i]+4.0*k3[i]+k4[i])/6.0;
	}
	return [t+dt, ynp1];
}

var _rk_saved_t; var _rk_halfdt; var _rk_y2 = new Array();
function rk4_auto (ynref, dydtref, t, dt, arg4) {
	_rk_saved_t = t;

	if (dt == 0.0) { dt = 0.1; }
	var errors = new Array(); var epsilon; var epsilon_mode = true;
	if (typeof arg4 == 'object') {
		errors = arg4; epsilon_mode = false;
	} else {
		epsilon = Math.abs(arg4); errors = null;
		if (epsilon == 0.0) { epsilon = .0000001; }
	}
	var ny = ynref.length; var i;

	var y1 = new Array(ny);
	_rk_y2.length = ny;
	var y3 = new Array(ny);
	var tmp;  // return values
	// _rk_saved_k0.length = ny;
	_rk_saved_k0 = dydtref(t, ynref);
	var resizings = 0;
	var highest_low_error = 0.1E-99; var highest_low_dt = 0.0;
	var lowest_high_error = 9.9E99;  var lowest_high_dt = 9.9E99;
	while (1) {
		_rk_halfdt = 0.5 * dt;
		_rk_use_saved_k0 = true;
		tmp = rk4(ynref, dydtref, t, dt);
		y1=tmp[1];
		tmp = rk4(ynref, dydtref, t, _rk_halfdt);
		_rk_y2=tmp[1];
		_rk_use_saved_k0 = false;
		tmp = rk4(_rk_y2, dydtref, t+_rk_halfdt, _rk_halfdt);
		y3=tmp[1];

		var relative_error;
		if (epsilon_mode) {
	 		var errmax = 0; var diff; var ymax = 0;
	 		for (i=0; i<ny; i++) {
	 			diff = Math.abs (y1[i]-y3[i]);
	 			if (errmax < diff) { errmax = diff; }
	 			if (ymax < Math.abs(ynref[i])) { ymax = Math.abs(ynref[i]); }
	 		}
			relative_error = errmax/(epsilon*ymax);
		} else {
			relative_error = 0.0;
	 		for (i=0; i<ny; i++) {
	 			diff = Math.abs(y1[i]-y3[i]) / Math.abs(errors[i]);
	 			if (relative_error < diff) { relative_error = diff; }
	 		}
		}
		if (relative_error < 0.60) {
			if (dt > highest_low_dt) {
				highest_low_error = relative_error; highest_low_dt = dt;
			}
		} else if (relative_error > 1.67) {
			if (dt < lowest_high_dt) {
				lowest_high_error = relative_error; lowest_high_dt = dt;
			}
		} else {
			break;
		}
		if (lowest_high_dt<9.8E99 && highest_low_dt>1.0E-99) { // interpolate
			var denom = Math.log(lowest_high_error/highest_low_error);
			if (highest_low_dt==0.0||highest_low_error==0.0||denom == 0.0) {
				dt = 0.5 * (highest_low_dt+lowest_high_dt);
			} else {
				dt = highest_low_dt*Math.pow( (lowest_high_dt/highest_low_dt),
				 ((Math.log(1.0/highest_low_error)) / denom) );
			}
		} else {
			var adjust = Math.pow(relative_error,-0.2);
			if (Math.abs(adjust) > 2.0) {
				dt *= 2.0;  // prevent infinity if 4th-order is exact ...
			} else {
				dt *= adjust;
			}
		}
		resizings++;
		if (resizings>4 && highest_low_dt>1.0E-99) {
			// hope a small step forward gets us out of this mess ...
			dt = highest_low_dt;  _rk_halfdt = 0.5 * dt;
			_rk_use_saved_k0 = true;
			tmp = rk4(ynref, dydtref, t, _rk_halfdt);
			_rk_y2=tmp[1];
			_rk_use_saved_k0 = false;
			tmp = rk4(_rk_y2, dydtref, t+_rk_halfdt, _rk_halfdt);
			y3=tmp[1];
			break;
		}
	}
	return [t+dt, dt, y3];
}

function rk4_auto_midpoint () {
	return [_rk_saved_t+_rk_halfdt, _rk_y2];
}

// ---------------------- EXPORT_OK routines ----------------------

function rk4_ralston (ynref, dydtref, t, dt) {
	var ny = ynref.length; var i;
	var alpha1=0.4; var alpha2 = 0.4557372542;
	var k0 = new Array(ny);
	k0 = dydtref(t, ynref);
	for (i=0; i<ny; i++) { k0[i] *= dt; }

	var k1 = new Array(ny);
	for (i=0; i<ny; i++) { k1[i] = ynref[i] + 0.4*k0[i]; }
	k1 = dydtref(t + alpha1*dt, k1);
	for (i=0; i<ny; i++) { k1[i] *= dt; }

	var k2 = new Array(ny);
	for (i=0; i<ny; i++) {
		k2[i] = ynref[i] + 0.2969776*k0[i] + 0.15875966*k1[i];
	}
	k2 = dydtref(t + alpha2*dt, k2);
	for (i=0; i<ny; i++) { k2[i] *= dt; }

	var k3 = new Array(ny);
	for (i=0; i<ny; i++) {
		k3[i] = ynref[i] + 0.21810038*k0[i] - 3.0509647*k1[i]
		 + 3.83286432*k2[i];
	}
	k3 = dydtref(t+dt, k3);
	for (i=0; i<ny; i++) { k3[i] *= dt; }

	var ynp1 = new Array(ny);
	for (i=0; i<ny; i++) {
		ynp1[i] = ynref[i] + 0.17476028*k0[i]
		 - 0.55148053*k1[i] + 1.20553547*k2[i] + 0.17118478*k3[i];
	}
	return [t+dt, ynp1];
}
function rk4_classical (ynref, dydtref, t, dt) {
	// The Classical 4th-order Runge-Kutta Method, see Gear p35
	var ny = ynref.length; var i;
	var k0 = new Array(ny);
	k0 = dydtref(t, ynref);
	for (i=0; i<ny; i++) { k0[i] *= dt; }

	var eta1 = new Array(ny);
	for (i=0; i<ny; i++) { eta1[i] = ynref[i] + 0.5*k0[i]; }
	var k1 = new Array(ny);
	k1 = dydtref(t+0.5*dt, eta1);
	for (i=0; i<ny; i++) { k1[i] *= dt; }

	var eta2 = new Array(ny);
	for (i=0; i<ny; i++) { eta2[i] = ynref[i] + 0.5*k1[i]; }
	var k2 = new Array(ny);
	k2 = dydtref(t+0.5*dt, eta2);
	for (i=0; i<ny; i++) { k2[i] *= dt; }

	var eta3 = new Array(ny);
	for (i=0; i<ny; i++) { eta3[i] = ynref[i] + k2[i]; }
	var k3 = new Array(ny);
	k3 = dydtref(t+dt, eta3);
	for (i=0; i<ny; i++) { k3[i] *= dt; }

	var ynp1 = new Array(ny);
	for (i=0; i<ny; i++) {
		ynp1[i] = ynref[i] +
		 (k0[i] + 2.0*k1[i] + 2.0*k2[i] + k3[i]) / 6.0;
	}
	return [t+dt, ynp1];
}
// --------------------- end of RungeKutta.js ----------------------

